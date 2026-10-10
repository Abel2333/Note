#!/usr/bin/env python3
"""Run deterministic finite checks and source mappings for the MoE note.

The checks exercise finite examples and local derivatives only. They do not
establish general training quality, expert specialization, or convergence.
The process exits with status 0 only when every check passes.
"""

from __future__ import annotations

import math
import re
import sys
import unittest
from collections import Counter
from collections.abc import Sequence
from pathlib import Path

FINITE_DIFFERENCE_STEP = 1e-6
FINITE_DIFFERENCE_TOLERANCE = 2e-6
FLOAT_TOLERANCE = 1e-12

# Maps executable checks to their one-to-one Typst anchors.
CHECK_LABELS = {
    "fixed_support_gradient": "fixed-support-gradient",
    "top_one_gradient": "top-one-gradient",
    "support_change": "support-change",
    "zloss_counterexample": "zloss-counterexample",
    "balance_stopgrad": "balance-stopgrad",
    "partial_drop": "partial-drop",
    "shared_budget_ledger": "shared-budget-ledger",
    "sign_feedback_cycle": "sign-feedback-cycle",
    "affinity_bias_selection": "affinity-bias-selection",
}

MOE_NOTE_PATH = (
    Path(__file__).resolve().parents[1]
    / "notes"
    / "Machine_Learning"
    / "Deep_Learning"
    / "Mixture_of_Experts.typ"
)
_APPENDIX_START_PATTERN = re.compile(
    r"(?m)^\s*=\s+Appendix:[ \t]+Finite[ \t]+Examples[ \t]+and[ \t]+Limits[ \t]+<finite-examples>\s*$"
)
_SOURCES_START_PATTERN = re.compile(
    r"(?m)^\s*=\s+Sources[ \t]+and[ \t]+Further[ \t]+Reading[ \t]+<sources>\s*$"
)
_APPENDIX_MAPPING_PATTERN = re.compile(
    r"""
    \[\s*\#ref\(\s*<(?P<label>[a-z0-9-]+)\s*>\s*\)\s*\]
    \s*,\s*
    \[\s*`(?P<check_name>[a-z0-9_]+)`\s*\]
    """,
    re.VERBOSE,
)
_HEADING_ANCHOR_PATTERN = re.compile(
    r"(?m)^\s*=+\s+[^\n]*?<(?P<label>[a-z0-9-]+)>\s*$"
)


def _appendix_text(note_text: str) -> str:
    appendix_start = _APPENDIX_START_PATTERN.search(note_text)
    if appendix_start is None:
        raise ValueError("could not find the finite-examples appendix")
    sources_start = _SOURCES_START_PATTERN.search(note_text, appendix_start.end())
    if sources_start is None:
        raise ValueError("could not find the sources section after the appendix")
    return note_text[appendix_start.start() : sources_start.start()]


def validate_moe_note_mapping(note_text: str | None = None) -> None:
    """Validate appendix check mappings against the MoE note's labeled headings.

    Args:
        note_text: Optional in-memory Typst source. When omitted, read the
            repository's ``Mixture_of_Experts.typ`` using UTF-8.

    Returns:
        None when every configured check has one appendix row and one heading
        anchor, with no extra, missing, or duplicate mappings.

    Raises:
        ValueError: If the appendix table, configured labels, or heading
            anchors do not form a one-to-one mapping.

    Side effects:
        Reads ``MOE_NOTE_PATH`` when ``note_text`` is omitted.
    """
    if note_text is None:
        note_text = MOE_NOTE_PATH.read_text(encoding="utf-8")

    mappings = [
        (match.group("label"), match.group("check_name"))
        for match in _APPENDIX_MAPPING_PATTERN.finditer(_appendix_text(note_text))
    ]
    table_labels = [label for label, _ in mappings]
    table_check_names = [check_name for _, check_name in mappings]
    duplicate_table_labels = sorted(
        label for label, count in Counter(table_labels).items() if count > 1
    )
    duplicate_table_checks = sorted(
        check_name for check_name, count in Counter(table_check_names).items() if count > 1
    )
    if duplicate_table_labels or duplicate_table_checks:
        raise ValueError("appendix mappings contain duplicate labels or check names")

    expected_labels = set(CHECK_LABELS.values())
    expected_check_names = set(CHECK_LABELS)
    if len(expected_labels) != len(CHECK_LABELS):
        raise ValueError("CHECK_LABELS assigns one label to more than one check")
    if set(table_labels) != expected_labels or set(table_check_names) != expected_check_names:
        raise ValueError("appendix mappings do not match CHECK_LABELS")

    expected_mappings = {
        (label, check_name) for check_name, label in CHECK_LABELS.items()
    }
    if set(mappings) != expected_mappings:
        raise ValueError("appendix labels and check names are paired incorrectly")

    anchor_counts = Counter(
        match.group("label") for match in _HEADING_ANCHOR_PATTERN.finditer(note_text)
    )
    invalid_anchors = [
        label for label in expected_labels if anchor_counts[label] != 1
    ]
    if invalid_anchors:
        raise ValueError("mapped labels must have exactly one heading anchor")


def _logsumexp(values: Sequence[float]) -> float:
    anchor = max(values)
    return anchor + math.log(sum(math.exp(value - anchor) for value in values))


def _softmax(values: Sequence[float]) -> tuple[float, ...]:
    log_normalizer = _logsumexp(values)
    return tuple(math.exp(value - log_normalizer) for value in values)


def _top_k_indices(values: Sequence[float], count: int) -> tuple[int, ...]:
    return tuple(sorted(range(len(values)), key=lambda index: (-values[index], index))[:count])


def _selected_softmax(logits: Sequence[float], support: Sequence[int]) -> tuple[float, ...]:
    selected_logits = tuple(logits[index] for index in support)
    return _softmax(selected_logits)


def _selected_output(
    logits: Sequence[float], support: Sequence[int], expert_outputs: Sequence[float]
) -> float:
    weights = _selected_softmax(logits, support)
    return sum(weight * expert_outputs[index] for weight, index in zip(weights, support))


def _balance_gradient(load_fraction: Sequence[float], probability: Sequence[float]) -> tuple[float, ...]:
    """Return the stop-gradient balance direction for one softmax vector.

    Args:
        load_fraction: Empirical expert fractions treated as constants.
        probability: A normalized softmax probability vector.

    Returns:
        The gradient of ``E * sum_i load_fraction_i * probability_i`` with
        respect to the corresponding logits, where ``E`` is the expert count.

    Raises:
        ValueError: If the vectors have different lengths or probabilities do
            not sum to one within ``FLOAT_TOLERANCE``.

    Side effects:
        None.
    """
    if len(load_fraction) != len(probability) or not probability:
        raise ValueError("load fractions and probabilities must have one shared length")
    if abs(sum(probability) - 1.0) > FLOAT_TOLERANCE:
        raise ValueError("probabilities must be normalized")
    average_load = sum(load * prob for load, prob in zip(load_fraction, probability))
    expert_count = len(probability)
    return tuple(
        expert_count * prob * (load - average_load)
        for load, prob in zip(load_fraction, probability)
    )


def _sign(value: float) -> int:
    if value > 0.0:
        return 1
    if value < 0.0:
        return -1
    return 0


class MoEMathChecks(unittest.TestCase):
    """Check the note's finite routing examples through public scalar formulas."""

    def test_matches_fixed_support_gradient_to_finite_difference(self) -> None:
        logits = (math.log(4.0), math.log(2.0), 0.0)
        support = (0, 1)
        expert_outputs = (0.0, 1.0, 2.0)
        routed_output = _selected_output(logits, support, expert_outputs)
        weights = _selected_softmax(logits, support)
        analytic_gradient = tuple(
            weights[position] * (expert_outputs[index] - routed_output)
            for position, index in enumerate(support)
        )
        self.assertAlmostEqual(analytic_gradient[0], -2.0 / 9.0, delta=FLOAT_TOLERANCE)
        self.assertAlmostEqual(analytic_gradient[1], 2.0 / 9.0, delta=FLOAT_TOLERANCE)

        for position, index in enumerate(support):
            plus = list(logits)
            minus = list(logits)
            plus[index] += FINITE_DIFFERENCE_STEP
            minus[index] -= FINITE_DIFFERENCE_STEP
            finite_difference = (
                _selected_output(plus, support, expert_outputs)
                - _selected_output(minus, support, expert_outputs)
            ) / (2.0 * FINITE_DIFFERENCE_STEP)
            self.assertLessEqual(
                abs(finite_difference - analytic_gradient[position]),
                FINITE_DIFFERENCE_TOLERANCE,
            )

        outside_plus = list(logits)
        outside_minus = list(logits)
        outside_plus[2] += FINITE_DIFFERENCE_STEP
        outside_minus[2] -= FINITE_DIFFERENCE_STEP
        outside_gradient = (
            _selected_output(outside_plus, support, expert_outputs)
            - _selected_output(outside_minus, support, expert_outputs)
        ) / (2.0 * FINITE_DIFFERENCE_STEP)
        self.assertAlmostEqual(outside_gradient, 0.0, delta=FLOAT_TOLERANCE)

    def test_distinguishes_normalized_and_full_softmax_top_one_gradients(self) -> None:
        logits = (math.log(4.0), math.log(2.0), 0.0)
        selected_expert = 0
        normalized_support = (selected_expert,)
        expert_outputs = (2.0, 1.0, 0.0)

        plus = list(logits)
        minus = list(logits)
        plus[selected_expert] += FINITE_DIFFERENCE_STEP
        minus[selected_expert] -= FINITE_DIFFERENCE_STEP
        normalized_gradient = (
            _selected_output(plus, normalized_support, expert_outputs)
            - _selected_output(minus, normalized_support, expert_outputs)
        ) / (2.0 * FINITE_DIFFERENCE_STEP)
        self.assertAlmostEqual(normalized_gradient, 0.0, delta=FLOAT_TOLERANCE)

        def full_softmax_top_one_output(candidate_logits: Sequence[float]) -> float:
            return _softmax(candidate_logits)[selected_expert] * expert_outputs[selected_expert]

        full_probability = _softmax(logits)[selected_expert]
        expected_full_gradient = expert_outputs[selected_expert] * full_probability * (1.0 - full_probability)
        full_gradient = (
            full_softmax_top_one_output(plus) - full_softmax_top_one_output(minus)
        ) / (2.0 * FINITE_DIFFERENCE_STEP)
        self.assertGreater(abs(full_gradient), 0.1)
        self.assertAlmostEqual(full_gradient, expected_full_gradient, delta=FINITE_DIFFERENCE_TOLERANCE)

    def test_can_change_support_by_updating_only_selected_logits(self) -> None:
        logits = (math.log(4.0), math.log(2.0), 0.0)
        old_support = _top_k_indices(logits, 2)
        gradient = (-2.0 / 9.0, 2.0 / 9.0, 0.0)
        learning_rate = 4.5 * math.log(4.0)
        updated_logits = tuple(
            value - learning_rate * derivative
            for value, derivative in zip(logits, gradient)
        )
        new_support = _top_k_indices(updated_logits, 2)

        self.assertEqual(old_support, (0, 1))
        self.assertEqual(gradient[2], 0.0)
        self.assertEqual(new_support, (0, 2))

    def test_exhibits_zero_zloss_with_large_logit_span(self) -> None:
        spans = []
        for epsilon in (1e-6, 1e-12):
            logits = (math.log1p(-epsilon), math.log(epsilon))
            log_partition = _logsumexp(logits)
            spans.append(logits[0] - logits[1])
            self.assertAlmostEqual(log_partition, 0.0, delta=FLOAT_TOLERANCE)
            self.assertAlmostEqual(log_partition * log_partition, 0.0, delta=FLOAT_TOLERANCE)
        self.assertGreater(spans[1], spans[0] + 10.0)

    def test_has_silent_uniform_load_but_nonzero_stop_gradient_direction(self) -> None:
        uniform_probability = (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)
        uniform_load = (1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)
        unbalanced_load = (1.0 / 2.0, 1.0 / 3.0, 1.0 / 6.0)

        silent_gradient = _balance_gradient(uniform_load, uniform_probability)
        active_gradient = _balance_gradient(unbalanced_load, uniform_probability)
        for value in silent_gradient:
            self.assertAlmostEqual(value, 0.0, delta=FLOAT_TOLERANCE)
        self.assertGreater(max(abs(value) for value in active_gradient), 0.1)
        self.assertAlmostEqual(sum(active_gradient), 0.0, delta=FLOAT_TOLERANCE)

    def test_keeps_remaining_route_and_shared_branch_after_partial_drop(self) -> None:
        shared_output = 3.0
        routed_weights = (0.4, 0.6)
        acceptance_mask = (1.0, 0.0)
        routed_expert_outputs = (2.0, 7.0)
        output = shared_output + sum(
            weight * accepted * expert_output
            for weight, accepted, expert_output in zip(
                routed_weights, acceptance_mask, routed_expert_outputs
            )
        )

        self.assertAlmostEqual(output, 3.8, delta=FLOAT_TOLERANCE)
        self.assertNotEqual(output, 0.0)
        self.assertGreater(output, shared_output)

    def test_separates_routed_requests_from_shared_active_count(self) -> None:
        routed_expert_count = 6
        shared_expert_count = 2
        token_count = 8
        expert_count = 8
        capacity_factor = 1.0
        support = tuple(range(routed_expert_count))
        active_expert_count = routed_expert_count + shared_expert_count
        capacity = math.ceil(
            capacity_factor * token_count * routed_expert_count / expert_count
        )
        routed_requests = token_count * routed_expert_count

        self.assertEqual(len(support), 6)
        self.assertEqual(active_expert_count, 8)
        self.assertEqual(capacity, 6)
        self.assertEqual(routed_requests, 48)
        self.assertNotEqual(routed_requests, token_count * active_expert_count)

    def test_demonstrates_two_cycle_for_fixed_step_sign_feedback(self) -> None:
        bias = (0.0, 0.0)
        states = [bias]
        for _ in range(2):
            selected = 0 if bias[0] >= bias[1] else 1
            load = (1.0, 0.0) if selected == 0 else (0.0, 1.0)
            mean_load = sum(load) / len(load)
            bias = tuple(
                value + _sign(mean_load - expert_load)
                for value, expert_load in zip(bias, load)
            )
            states.append(bias)

        self.assertNotEqual(states[0], states[1])
        self.assertEqual(states[0], states[2])

    def test_distinguishes_logit_and_sigmoid_affinity_bias_selection(self) -> None:
        logits = (4.0, 0.0)
        bias = (0.0, 1.0)
        logit_selection = _top_k_indices(
            tuple(value + offset for value, offset in zip(logits, bias)), 1
        )
        affinity_selection = _top_k_indices(
            tuple(
                1.0 / (1.0 + math.exp(-value)) + offset
                for value, offset in zip(logits, bias)
            ),
            1,
        )

        self.assertEqual(logit_selection, (0,))
        self.assertEqual(affinity_selection, (1,))


class MoENoteMappingChecks(unittest.TestCase):
    """Exercise the public source-mapping validation interface."""

    def _note_text(self) -> str:
        return MOE_NOTE_PATH.read_text(encoding="utf-8")

    def test_accepts_the_real_note_mapping(self) -> None:
        validate_moe_note_mapping()

    def test_rejects_swapped_appendix_check_names(self) -> None:
        note_text = self._note_text()
        fixed_pair = "[#ref(<fixed-support-gradient>)], [`fixed_support_gradient`]"
        top_one_pair = "[#ref(<top-one-gradient>)], [`top_one_gradient`]"
        self.assertIn(fixed_pair, note_text)
        self.assertIn(top_one_pair, note_text)
        mutated = note_text.replace(
            fixed_pair,
            "[#ref(<fixed-support-gradient>)], [`top_one_gradient`]",
            1,
        ).replace(
            top_one_pair,
            "[#ref(<top-one-gradient>)], [`fixed_support_gradient`]",
            1,
        )

        with self.assertRaises(ValueError):
            validate_moe_note_mapping(mutated)

    def test_rejects_duplicate_appendix_mapping(self) -> None:
        note_text = self._note_text()
        final_row = (
            "  [#ref(<affinity-bias-selection>)], [`affinity_bias_selection`], "
            "[Bias placement before or after sigmoid can change selection.],\n)"
        )
        duplicate_row = (
            "  [#ref(<fixed-support-gradient>)], [`fixed_support_gradient`], "
            "[A selected-softmax local derivative agrees with a central finite "
            "difference while support is fixed.],\n"
        )
        self.assertIn(final_row, note_text)
        mutated = note_text.replace(final_row, duplicate_row + final_row, 1)

        with self.assertRaises(ValueError):
            validate_moe_note_mapping(mutated)

    def test_rejects_duplicate_heading_anchor(self) -> None:
        note_text = self._note_text()
        heading = "== Fixed-support derivative <fixed-support-gradient>"
        self.assertIn(heading, note_text)
        mutated = note_text.replace(
            heading,
            heading + "\n\n== Duplicate fixed support <fixed-support-gradient>",
            1,
        )

        with self.assertRaises(ValueError):
            validate_moe_note_mapping(mutated)

    def test_rejects_missing_heading_anchor(self) -> None:
        note_text = self._note_text()
        heading = "== Fixed-support derivative <fixed-support-gradient>"
        self.assertIn(heading, note_text)
        mutated = note_text.replace(" <fixed-support-gradient>", "", 1)

        with self.assertRaises(ValueError):
            validate_moe_note_mapping(mutated)


def main() -> int:
    """Run the deterministic MoE math checks and return a process status.

    Returns:
        Zero when every finite check passes and one otherwise.

    Side effects:
        Writes the standard unittest report to stderr.
    """
    try:
        validate_moe_note_mapping()
    except ValueError as error:
        print(f"MoE note mapping validation failed: {error}", file=sys.stderr)
        return 1

    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main())
