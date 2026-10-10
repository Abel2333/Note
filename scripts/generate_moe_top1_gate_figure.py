#!/usr/bin/env python3
"""Generate the fixed-support top-1 MoE gate comparison as a deterministic SVG."""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = REPOSITORY_ROOT / "assets" / "diagrams" / "moe_top1_gate_comparison.svg"


@dataclass(frozen=True)
class GateCurves:
    """Hold fixed-support top-1 gate coefficients and local derivatives.

    Attributes:
        deltas: Strictly positive differences ``a_1 - a_2`` for a fixed
            selected support ``S = {1}``.
        selected_normalized_weight: One-element selected-set normalization,
            which is one at every sampled delta.
        full_softmax_weight: First-expert full-softmax coefficient
            ``sigmoid(delta)``.
        selected_normalized_derivative: Local derivative of the selected-set
            coefficient with respect to delta, which is zero.
        full_softmax_derivative: Local derivative ``p_1 * (1 - p_1)``.
    """

    deltas: tuple[float, ...]
    selected_normalized_weight: tuple[float, ...]
    full_softmax_weight: tuple[float, ...]
    selected_normalized_derivative: tuple[float, ...]
    full_softmax_derivative: tuple[float, ...]


def top1_gate_curves(deltas: Sequence[float]) -> GateCurves:
    """Compute two-expert top-1 gate curves on a strictly positive fixed domain.

    Args:
        deltas: Finite values of ``a_1 - a_2`` that must each be greater than
            zero, so expert 1 remains the unique selected expert.

    Returns:
        Coefficients and their local gate-weight derivatives for selected-set
        normalization and full-softmax retention at every input delta.

    Raises:
        ValueError: If ``deltas`` is empty or has a non-finite or non-positive
            value.

    Side effects:
        None.
    """
    values = tuple(float(delta) for delta in deltas)
    if not values:
        raise ValueError("at least one positive delta is required")
    if any(not math.isfinite(delta) or delta <= 0.0 for delta in values):
        raise ValueError("deltas must be finite and strictly positive")

    probabilities = tuple(1.0 / (1.0 + math.exp(-delta)) for delta in values)
    return GateCurves(
        deltas=values,
        selected_normalized_weight=(1.0,) * len(values),
        full_softmax_weight=probabilities,
        selected_normalized_derivative=(0.0,) * len(values),
        full_softmax_derivative=tuple(
            probability * (1.0 - probability) for probability in probabilities
        ),
    )


def _assert_close(actual: float, expected: float, tolerance: float = 1e-9) -> None:
    if abs(actual - expected) > tolerance:
        raise AssertionError(f"expected {expected!r}, received {actual!r}")


def _run_behavior_checks() -> int:
    checks_run = 0

    curves = top1_gate_curves((math.log(3.0),))
    _assert_close(curves.selected_normalized_weight[0], 1.0)
    _assert_close(curves.selected_normalized_derivative[0], 0.0)
    _assert_close(curves.full_softmax_weight[0], 0.75)
    _assert_close(curves.full_softmax_derivative[0], 3.0 / 16.0)
    checks_run += 1

    curves = top1_gate_curves((0.25, 1.0, 3.0))
    if not all(
        left < right
        for left, right in zip(curves.full_softmax_weight, curves.full_softmax_weight[1:])
    ):
        raise AssertionError("full-softmax coefficients must increase on positive deltas")
    if not all(
        left > right
        for left, right in zip(
            curves.full_softmax_derivative, curves.full_softmax_derivative[1:]
        )
    ):
        raise AssertionError("full-softmax derivatives must decrease on positive deltas")
    checks_run += 1

    delta = 1.25
    step = 1e-6
    plus = top1_gate_curves((delta + step,)).full_softmax_weight[0]
    minus = top1_gate_curves((delta - step,)).full_softmax_weight[0]
    finite_difference = (plus - minus) / (2.0 * step)
    analytic = top1_gate_curves((delta,)).full_softmax_derivative[0]
    _assert_close(finite_difference, analytic, tolerance=2e-7)
    checks_run += 1

    invalid_inputs = ((), (0.0,), (-0.25,), (math.inf,), (math.nan,))
    for invalid in invalid_inputs:
        try:
            top1_gate_curves(invalid)
        except ValueError:
            continue
        raise AssertionError(f"invalid deltas {invalid!r} were accepted")
    checks_run += 1

    return checks_run


def _sample_deltas() -> tuple[float, ...]:
    point_count = 200
    minimum = 0.05
    maximum = 5.0
    return tuple(
        minimum + (maximum - minimum) * index / (point_count - 1)
        for index in range(point_count)
    )


def _resolve_output(value: str | None) -> Path:
    output = DEFAULT_OUTPUT if value is None else Path(value).resolve()
    try:
        output.relative_to(REPOSITORY_ROOT)
    except ValueError as error:
        raise ValueError("output must stay inside the repository") from error
    if output.suffix.lower() != ".svg":
        raise ValueError("output must use the .svg extension")
    return output


def _write_svg(output: Path) -> None:
    import matplotlib

    matplotlib.use("svg")
    from matplotlib import pyplot as plt

    matplotlib.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 10,
            "svg.fonttype": "path",
            "svg.hashsalt": "moe-top1-gate-comparison-v1",
        }
    )
    curves = top1_gate_curves(_sample_deltas())
    figure, axes = plt.subplots(1, 2, figsize=(10.8, 4.4), layout="constrained")
    figure.suptitle(
        "Two experts: Delta = a1 - a2 > 0, fixed S = {1}, no ties, no drop, route scale = 1",
        fontsize=11,
    )

    normalized_style = {"color": "#27364A", "linewidth": 2.2, "linestyle": "-"}
    softmax_style = {"color": "#007C83", "linewidth": 2.2, "linestyle": "--"}

    coefficient_axis = axes[0]
    coefficient_axis.plot(
        curves.deltas,
        curves.selected_normalized_weight,
        label="selected-set normalization: 1",
        **normalized_style,
    )
    coefficient_axis.plot(
        curves.deltas,
        curves.full_softmax_weight,
        label="full softmax: sigmoid(Delta)",
        **softmax_style,
    )
    coefficient_axis.set_title("Gate coefficient on fixed support", fontsize=11)
    coefficient_axis.set_xlabel("Delta = a1 - a2 > 0")
    coefficient_axis.set_ylabel("selected route coefficient")
    coefficient_axis.set_xlim(curves.deltas[0], curves.deltas[-1])
    coefficient_axis.set_ylim(0.45, 1.04)
    coefficient_axis.grid(axis="y", color="#B8C1C8", linewidth=0.7)
    coefficient_axis.legend(frameon=False, loc="lower right", fontsize=8.5)

    derivative_axis = axes[1]
    derivative_axis.plot(
        curves.deltas,
        curves.selected_normalized_derivative,
        label="selected-set normalization: 0",
        **normalized_style,
    )
    derivative_axis.plot(
        curves.deltas,
        curves.full_softmax_derivative,
        label="full softmax: p1(1 - p1)",
        **softmax_style,
    )
    derivative_axis.set_title("Local gate-weight derivative", fontsize=11)
    derivative_axis.set_xlabel("Delta = a1 - a2 > 0")
    derivative_axis.set_ylabel("d gate weight / d Delta")
    derivative_axis.set_xlim(curves.deltas[0], curves.deltas[-1])
    derivative_axis.set_ylim(-0.012, 0.27)
    derivative_axis.grid(axis="y", color="#B8C1C8", linewidth=0.7)
    derivative_axis.legend(frameon=False, loc="upper right", fontsize=8.5)

    output.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(
        output,
        format="svg",
        metadata={"Date": None, "Creator": "MoE top-1 gate figure generator"},
    )
    # Normalize Matplotlib path-line padding for a clean checked-in artifact.
    svg = output.read_text(encoding="utf-8")
    output.write_text(
        "\n".join(line.rstrip() for line in svg.splitlines()) + "\n",
        encoding="utf-8",
    )
    plt.close(figure)


def main(argv: Sequence[str] | None = None) -> int:
    """Run deterministic curve checks or write the checked-in SVG.

    Args:
        argv: Optional command-line arguments. ``--check`` runs only numeric
            behavior checks. ``--output`` selects an SVG path inside this
            repository; omitting it writes the checked-in asset.

    Returns:
        Zero on success and one when validation or rendering fails.

    Side effects:
        ``--check`` has no file side effects. Generation creates or overwrites
        one SVG beneath this repository.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="run deterministic curve behavior checks without writing an SVG",
    )
    parser.add_argument(
        "--output",
        help="write an SVG to this repository instead of the checked-in asset",
    )
    arguments = parser.parse_args(argv)
    if arguments.check and arguments.output:
        parser.error("--check cannot be combined with --output")

    try:
        if arguments.check:
            checks_run = _run_behavior_checks()
            print(
                "top-1 gate curve checks passed: "
                f"{checks_run}/4 (invalid domains: empty, zero, negative, non-finite)"
            )
            return 0
        _write_svg(_resolve_output(arguments.output))
    except (AssertionError, OSError, ValueError) as error:
        print(f"top-1 gate figure generation failed: {error}", file=sys.stderr)
        return 1

    print(f"wrote {_resolve_output(arguments.output).relative_to(REPOSITORY_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
