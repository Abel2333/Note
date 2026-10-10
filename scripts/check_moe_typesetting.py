#!/usr/bin/env python3
"""Check indexed MoE function parameters with Typst content introspection.

The checker is intentionally limited to the indexed ``TopK``, ``E_i``, and
``E_j`` forms used by the MoE note. It asks Typst for public content fields so
that a source-space gap is not mistaken for a proof of attachment structure.
"""

from __future__ import annotations

import argparse
import io
import json
import math
import re
import subprocess
import sys
import unittest
from collections import Counter
from contextlib import redirect_stderr
from dataclasses import dataclass
from pathlib import Path
from unittest import mock

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
MOE_NOTE_PATH = (
    REPOSITORY_ROOT
    / "notes"
    / "Machine_Learning"
    / "Deep_Learning"
    / "Mixture_of_Experts.typ"
)
TYPST_INSPECTION_TIMEOUT_SECONDS = 15
ROUTING_AUTHOR_END_ANCHOR = "// moe-typesetting-routing-end:"
INDEXED_FUNCTION_PATTERN = re.compile(
    r'(?P<function>op\("TopK"\)_i|E_[ij])'
    r'(?P<gap>[ \t\r\n]*)'
    r'(?P<argument>\((?:[^()]|\([^()]*\))*\))'
)
REQUIRED_AUTHOR_BLOCKS = (
    (
        "routing-objects",
        ROUTING_AUTHOR_END_ANCHOR,
        Counter(
            {
                'op("TopK")_i(a_(t,i))': 1,
                "E_i(x_t)": 2,
            }
        ),
    ),
    (
        "fixed-support-gradient",
        "<top-one-gradient>",
        Counter(
            {
                "E_i(x_t)": 1,
                "E_j(x_t)": 1,
            }
        ),
    ),
    (
        "sign-feedback-cycle",
        "<case-studies>",
        Counter(
            {
                'op("TopK")_i(a\'_(t,i))': 1,
            }
        ),
    ),
)


@dataclass(frozen=True)
class Candidate:
    """Represent one indexed function call extracted from the MoE source.

    Attributes:
        expression: The exact math fragment sent to Typst.
        normalized: The same fragment with normal whitespace removed.
        line: One-based source line where the function starts.
        start: Zero-based source offset where the fragment starts.
        end: Zero-based source offset immediately after the fragment.
    """

    expression: str
    normalized: str
    line: int
    start: int
    end: int


def _skip_string(source: str, start: int) -> int:
    index = start + 1
    while index < len(source):
        if source[index] == "\\":
            index += 2
        elif source[index] == '"':
            return index + 1
        else:
            index += 1
    return len(source)


def _math_fragments(source: str) -> list[tuple[int, int]]:
    """Return inline-math spans while skipping this note's strings, comments, and raw text."""
    fragments = []
    index = 0
    while index < len(source):
        if source.startswith("//", index):
            newline = source.find("\n", index + 2)
            index = len(source) if newline < 0 else newline + 1
        elif source.startswith("/*", index):
            end = source.find("*/", index + 2)
            index = len(source) if end < 0 else end + 2
        elif source[index] == '"':
            index = _skip_string(source, index)
        elif source[index] == "`":
            end = source.find("`", index + 1)
            index = len(source) if end < 0 else end + 1
        elif source[index] == "$":
            end = source.find("$", index + 1)
            if end < 0:
                break
            fragments.append((index + 1, end))
            index = end + 1
        else:
            index += 1
    return fragments


def _extract_candidates(source: str) -> list[Candidate]:
    candidates = []
    for math_start, math_end in _math_fragments(source):
        for match in INDEXED_FUNCTION_PATTERN.finditer(source, math_start, math_end):
            expression = match.group(0)
            start = match.start()
            candidates.append(
                Candidate(
                    expression=expression,
                    normalized=re.sub(r"\s+", "", expression),
                    line=source.count("\n", 0, start) + 1,
                    start=start,
                    end=match.end(),
                )
            )
    return candidates


def _block_bounds(source: str, start_label: str, end_marker: str) -> tuple[int, int]:
    start_marker = f"<{start_label}>"
    start = source.find(start_marker)
    if start < 0:
        raise ValueError(f"could not find source anchor {start_marker}")
    start += len(start_marker)
    end = source.find(end_marker, start)
    if end < 0:
        raise ValueError(f"could not find source boundary {end_marker!r}")
    return start, end


def _required_author_candidates(
    source: str, candidates: list[Candidate] | None = None
) -> list[Candidate]:
    required = []
    scoped_candidates = _extract_candidates(source) if candidates is None else candidates
    for start_label, end_marker, expected in REQUIRED_AUTHOR_BLOCKS:
        start, end = _block_bounds(source, start_label, end_marker)
        block_candidates = [
            candidate
            for candidate in scoped_candidates
            if start <= candidate.start and candidate.end <= end
        ]
        actual = Counter(
            candidate.normalized
            for candidate in block_candidates
            if candidate.normalized in expected
        )
        if actual != expected:
            raise ValueError(
                f"author formulas between <{start_label}> and {end_marker!r} "
                f"do not match the required indexed calls: expected {dict(expected)}, "
                f"found {dict(actual)}"
            )
        for normalized in expected:
            required.extend(
                candidate
                for candidate in block_candidates
                if candidate.normalized == normalized
            )
    return required


def _typst_source(candidates: list[Candidate]) -> str:
    formulas = "\n".join(f"  ${candidate.expression}$," for candidate in candidates)
    return f'''#let formulas = (\n{formulas}\n)\n#let sequence-function = [].func()\n#let items = content => if content.func() == sequence-function {{ content.children }} else {{ (content,) }}\n#let inspect = formula => {{\n  let top-level = items(formula.body)\n  let attachments = top-level.filter(item => item.func() == math.attach)\n  let parentheses = top-level.filter(item => item.func() == math.lr)\n  let attachment = attachments.at(0, default: none)\n  let bottom = if attachment == none {{ none }} else {{ attachment.at("b", default: none) }}\n  let bottom-items = if bottom == none {{ () }} else {{ items(bottom) }}\n  (\n    top-attachment-count: attachments.len(),\n    top-parentheses-count: parentheses.len(),\n    bottom-contains-parentheses: bottom-items.any(item => item.func() == math.lr),\n  )\n}}\n#metadata(formulas.map(inspect)) <moe-indexed-functions>\n'''


def _inspect_with_typst(candidates: list[Candidate]) -> list[dict[str, object]]:
    command = [
        "typst",
        "eval",
        "--root",
        str(REPOSITORY_ROOT),
        "--in",
        "-",
        "--format",
        "json",
        "query(<moe-indexed-functions>).map(item => item.value)",
    ]
    try:
        result = subprocess.run(
            command,
            input=_typst_source(candidates),
            text=True,
            capture_output=True,
            check=False,
            cwd=REPOSITORY_ROOT,
            timeout=TYPST_INSPECTION_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            f"Typst content inspection timed out after {TYPST_INSPECTION_TIMEOUT_SECONDS} seconds"
        ) from error
    except OSError as error:
        raise RuntimeError(f"could not start Typst content inspection: {error}") from error
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(f"Typst content inspection failed: {detail}")

    try:
        queried = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"Typst emitted invalid inspection JSON: {error}") from error
    if len(queried) != 1 or not isinstance(queried[0], list):
        raise RuntimeError("Typst metadata query returned an unexpected result shape")
    results = queried[0]
    if len(results) != len(candidates) or not all(isinstance(item, dict) for item in results):
        raise RuntimeError("Typst inspection result does not align with the extracted calls")
    return results


def check_typesetting(source: str) -> list[str]:
    """Validate indexed-function attachment boundaries in MoE Typst source.

    Args:
        source: Complete in-memory contents of ``Mixture_of_Experts.typ``.

    Returns:
        Human-readable errors for malformed attachment boundaries. An empty list
        means the six protected author formulas and every indexed call in a
        real inline math fragment have a parameter group at the equation level.

    Raises:
        ValueError: If protected source anchors or their required calls are
            missing or duplicated.
        RuntimeError: If Typst cannot inspect the extracted math content.

    Side effects:
        Starts the installed ``typst`` CLI with an in-memory metadata document
        and a finite subprocess timeout.
    """
    candidates = _extract_candidates(source)
    required = _required_author_candidates(source, candidates)
    if not candidates:
        raise ValueError("could not find indexed TopK, E_i, or E_j calls in the MoE note")
    required_spans = {(candidate.start, candidate.end) for candidate in required}
    results = _inspect_with_typst(candidates)

    errors = []
    for candidate, result in zip(candidates, results):
        attachment_count = result.get("top-attachment-count")
        parentheses_count = result.get("top-parentheses-count")
        bottom_contains_parentheses = result.get("bottom-contains-parentheses")
        if (
            attachment_count != 1
            or parentheses_count < 1
            or bottom_contains_parentheses is not False
        ):
            protected = " protected author call" if (candidate.start, candidate.end) in required_spans else ""
            errors.append(
                f"line {candidate.line}:{protected} {candidate.expression!r} "
                f"has top attachments={attachment_count}, "
                f"top parentheses={parentheses_count}, "
                f"bottom contains parentheses={bottom_contains_parentheses}"
            )
    return errors


def _mutate_required_calls(source: str) -> str:
    required = _required_author_candidates(source)
    mutated = source
    for candidate in sorted(required, key=lambda item: item.start, reverse=True):
        broken = candidate.normalized
        mutated = mutated[: candidate.start] + broken + mutated[candidate.end :]
    return mutated


def _read_source() -> str:
    try:
        return MOE_NOTE_PATH.read_text(encoding="utf-8")
    except OSError as error:
        raise RuntimeError(f"could not read MoE source {MOE_NOTE_PATH}: {error}") from error


class _TypesettingCheckerRegressionTests(unittest.TestCase):
    source = ""

    def test_real_source_and_six_mutated_author_calls(self) -> None:
        with mock.patch.object(Path, "write_text") as write_text:
            self.assertEqual(check_typesetting(self.source), [])
            errors = check_typesetting(_mutate_required_calls(self.source))
        self.assertEqual(len(errors), 6)
        self.assertTrue(all("protected author call" in error for error in errors))
        write_text.assert_not_called()

    def test_scopes_candidates_to_math_and_preserves_global_positions(self) -> None:
        title = '#definition(title: "Selection, fusion, and acceptance")'
        replacement = '#definition(\n  title: "Selection, fusion, and acceptance",\n)'
        self.assertIn(title, self.source)
        source_with_non_math_text = (
            '#let code_label = "E_i(x_t) $op(\\"TopK\\")_i(a_(t,i))$"\n'
            '// $E_i(x_t)$\n'
            '/* $E_j(x_t)$ */\n'
            + self.source.replace(title, replacement, 1)
        )
        self.assertEqual(check_typesetting(source_with_non_math_text), [])

        expression = 'op("TopK")_i (a_(t,i))'
        start = source_with_non_math_text.index(expression)
        candidate = next(
            item for item in _extract_candidates(source_with_non_math_text) if item.start == start
        )
        self.assertEqual(candidate.line, source_with_non_math_text.count("\n", 0, start) + 1)
        self.assertEqual(candidate.end, start + len(expression))
        self.assertEqual(
            len(_extract_candidates(source_with_non_math_text)),
            len(_extract_candidates(self.source)),
        )

    def test_rejects_new_malformed_math_call(self) -> None:
        errors = check_typesetting(f"{self.source}\n$ E_i(x_t) $\n")
        self.assertEqual(len(errors), 1)
        self.assertNotIn("protected author call", errors[0])

    def test_missing_routing_anchor_is_not_a_binding_error(self) -> None:
        source_without_anchor = self.source.replace(ROUTING_AUTHOR_END_ANCHOR, "", 1)
        with self.assertRaisesRegex(ValueError, "could not find source boundary"):
            check_typesetting(source_without_anchor)

    def test_main_reports_typst_timeout_without_traceback_or_writes(self) -> None:
        stderr = io.StringIO()
        timeout = subprocess.TimeoutExpired(["typst", "eval"], TYPST_INSPECTION_TIMEOUT_SECONDS)
        with (
            mock.patch.object(Path, "read_text", return_value=self.source),
            mock.patch.object(Path, "write_text") as write_text,
            mock.patch.object(subprocess, "run", side_effect=timeout) as run,
            redirect_stderr(stderr),
        ):
            return_code = main([])

        message = stderr.getvalue()
        self.assertEqual(return_code, 1)
        self.assertIn("Typst content inspection timed out after", message)
        self.assertNotIn("Traceback", message)
        write_text.assert_not_called()
        timeout_value = run.call_args.kwargs.get("timeout")
        self.assertIsNotNone(timeout_value)
        self.assertTrue(math.isfinite(timeout_value))
        self.assertGreater(timeout_value, 0)

    def test_main_reports_missing_typst_without_traceback_or_writes(self) -> None:
        stderr = io.StringIO()
        with (
            mock.patch.object(Path, "read_text", return_value=self.source),
            mock.patch.object(Path, "write_text") as write_text,
            mock.patch.object(
                subprocess, "run", side_effect=FileNotFoundError("typst executable missing")
            ),
            redirect_stderr(stderr),
        ):
            return_code = main([])

        message = stderr.getvalue()
        self.assertEqual(return_code, 1)
        self.assertIn("could not start Typst content inspection", message)
        self.assertNotIn("Traceback", message)
        write_text.assert_not_called()

    def test_main_reports_missing_or_unreadable_source_without_traceback_or_writes(self) -> None:
        for failure in (FileNotFoundError("MoE source missing"), PermissionError("MoE source unreadable")):
            with self.subTest(error=type(failure).__name__):
                stderr = io.StringIO()
                with (
                    mock.patch.object(Path, "read_text", side_effect=failure),
                    mock.patch.object(Path, "write_text") as write_text,
                    mock.patch.object(subprocess, "run") as run,
                    redirect_stderr(stderr),
                ):
                    return_code = main([])

                message = stderr.getvalue()
                self.assertEqual(return_code, 1)
                self.assertIn("could not read MoE source", message)
                self.assertNotIn("Traceback", message)
                write_text.assert_not_called()
                run.assert_not_called()


def _run_self_tests(source: str) -> int:
    _TypesettingCheckerRegressionTests.source = source
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(
        _TypesettingCheckerRegressionTests
    )
    output = io.StringIO()
    result = unittest.TextTestRunner(stream=output, verbosity=0).run(suite)
    if not result.wasSuccessful():
        print("MoE typesetting self-test failed", file=sys.stderr)
        print(output.getvalue().rstrip(), file=sys.stderr)
        return 1
    print(f"self-test passed: {result.testsRun} typesetting regressions")
    return 0


def main(argv: list[str] | None = None) -> int:
    """Run the real-source checker or its deterministic regression suite.

    Args:
        argv: Optional command-line arguments. ``--self-test`` exercises the
            protected-call mutations, math-only extraction, and CLI I/O errors
            without writing the source file.

    Returns:
        Zero when the selected check succeeds; one for a detected typesetting
        defect or an inspection failure.

    Side effects:
        Reads the MoE note and invokes Typst. The self-test mutates only
        in-memory source strings and mocks filesystem and subprocess failures.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="run deterministic in-memory source and CLI failure regressions",
    )
    arguments = parser.parse_args(argv)

    try:
        source = _read_source()
        if arguments.self_test:
            return _run_self_tests(source)
        errors = check_typesetting(source)
    except (RuntimeError, ValueError) as error:
        print(f"MoE typesetting check failed: {error}", file=sys.stderr)
        return 1

    if errors:
        for error in errors:
            print(f"MoE typesetting check failed: {error}", file=sys.stderr)
        return 1

    print("MoE typesetting check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
