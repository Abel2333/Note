#!/usr/bin/env python3
"""Generate a deterministic SVG for the scalar Lagrangian-duality example."""

from __future__ import annotations

import argparse
import math
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = REPOSITORY_ROOT / "assets" / "diagrams" / "lagrangian_primal_dual_bounds.svg"


@dataclass(frozen=True)
class ScalarDuality:
    """Hold the analytic quantities used by the running scalar example.

    Attributes:
        multiplier: Nonnegative inequality multiplier.
        inner_minimizer: Unconstrained minimizer of the Lagrangian in x.
        dual_value: Dual-function value at the multiplier.
    """

    multiplier: float
    inner_minimizer: float
    dual_value: float


def scalar_duality(multiplier: float) -> ScalarDuality:
    """Evaluate the scalar Lagrangian minimizer and dual value.

    Args:
        multiplier: Finite nonnegative multiplier for the residual ``1 - x``.

    Returns:
        The inner minimizer ``x = multiplier / 2`` and the value
        ``g = multiplier - multiplier**2 / 4``.

    Raises:
        ValueError: If the multiplier is negative or non-finite.

    Side effects:
        None.
    """
    value = float(multiplier)
    if not math.isfinite(value) or value < 0.0:
        raise ValueError("multiplier must be finite and nonnegative")
    return ScalarDuality(value, value / 2.0, value - value * value / 4.0)


def _assert_close(actual: float, expected: float, tolerance: float = 1e-9) -> None:
    if abs(actual - expected) > tolerance:
        raise AssertionError(f"expected {expected!r}, received {actual!r}")


def _run_behavior_checks() -> int:
    checks_run = 0
    optimum = scalar_duality(2.0)
    _assert_close(optimum.inner_minimizer, 1.0)
    _assert_close(optimum.dual_value, 1.0)
    checks_run += 1

    sample = scalar_duality(1.0)
    _assert_close(sample.inner_minimizer, 0.5)
    _assert_close(sample.dual_value, 0.75)
    if sample.dual_value > 1.0:
        raise AssertionError("a dual value exceeded the primal optimum")
    checks_run += 1

    for invalid in (-0.01, math.inf, math.nan):
        try:
            scalar_duality(invalid)
        except ValueError:
            continue
        raise AssertionError(f"invalid multiplier {invalid!r} was accepted")
    checks_run += 1
    return checks_run


def _sample_values(start: float, stop: float, count: int) -> tuple[float, ...]:
    return tuple(start + (stop - start) * index / (count - 1) for index in range(count))


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
            "svg.hashsalt": "lagrangian-primal-dual-bounds-v1",
        }
    )
    xs = _sample_values(-1.0, 3.0, 240)
    multipliers = (0.0, 1.0, 2.0)
    lambdas = _sample_values(0.0, 4.0, 240)
    figure, axes = plt.subplots(1, 2, figsize=(10.8, 4.4), layout="constrained")

    primal_axis = axes[0]
    primal_axis.axvspan(1.0, 3.0, color="#E8F2EA", zorder=0, label="feasible x >= 1")
    primal_axis.plot(xs, [x * x for x in xs], color="#27364A", linewidth=2.4, label="objective x^2")
    curve_colors = ("#A84C2A", "#007C83", "#8D4F9E")
    for multiplier, color in zip(multipliers, curve_colors):
        values = [x * x + multiplier * (1.0 - x) for x in xs]
        data = scalar_duality(multiplier)
        primal_axis.plot(xs, values, color=color, linewidth=1.7, linestyle="--", label=f"L(x, {multiplier:g})")
        primal_axis.scatter(data.inner_minimizer, data.dual_value, color=color, s=28, zorder=4)
    primal_axis.scatter(1.0, 1.0, color="#111111", s=38, zorder=5, label="primal optimum (1, 1)")
    primal_axis.axvline(1.0, color="#52705A", linewidth=1.2, linestyle=":")
    primal_axis.set_title("Primal objective and Lagrangian curves", fontsize=11)
    primal_axis.set_xlabel("x")
    primal_axis.set_ylabel("value")
    primal_axis.set_xlim(-1.0, 3.0)
    primal_axis.set_ylim(-0.35, 4.35)
    primal_axis.grid(axis="y", color="#B8C1C8", linewidth=0.7)
    primal_axis.legend(frameon=False, loc="upper left", fontsize=7.5)

    dual_axis = axes[1]
    dual_values = [scalar_duality(multiplier).dual_value for multiplier in lambdas]
    dual_axis.plot(lambdas, dual_values, color="#007C83", linewidth=2.4, label="g(lambda) = lambda - lambda^2 / 4")
    dual_axis.axhline(1.0, color="#27364A", linewidth=1.4, linestyle="--", label="primal value p* = 1")
    dual_axis.scatter(2.0, 1.0, color="#111111", s=40, zorder=5, label="best lambda = 2")
    dual_axis.vlines(1.0, 0.75, 1.0, color="#A84C2A", linewidth=1.8, linestyle=":")
    dual_axis.scatter(1.0, 0.75, color="#A84C2A", s=28, zorder=5, label="illustrative bound gap")
    dual_axis.set_title("Concave dual lower bounds", fontsize=11)
    dual_axis.set_xlabel("lambda >= 0")
    dual_axis.set_ylabel("dual value")
    dual_axis.set_xlim(0.0, 4.0)
    dual_axis.set_ylim(0.0, 1.16)
    dual_axis.grid(axis="y", color="#B8C1C8", linewidth=0.7)
    dual_axis.legend(frameon=False, loc="lower left", fontsize=7.5)

    output.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(
        output,
        format="svg",
        metadata={"Date": None, "Creator": "Lagrangian duality figure generator"},
    )
    svg = output.read_text(encoding="utf-8")
    output.write_text("\n".join(line.rstrip() for line in svg.splitlines()) + "\n", encoding="utf-8")
    plt.close(figure)


def main(argv: Sequence[str] | None = None) -> int:
    """Run analytic checks or write the checked-in SVG.

    Args:
        argv: Optional arguments. ``--check`` runs only analytic checks;
            ``--output`` selects an SVG path inside this repository.

    Returns:
        Zero on success and one when validation or rendering fails.

    Side effects:
        Generation creates or overwrites one SVG beneath this repository.
        ``--check`` has no file side effects.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="run analytic checks without writing an SVG")
    parser.add_argument("--output", help="write an SVG to this repository instead of the checked-in asset")
    arguments = parser.parse_args(argv)
    if arguments.check and arguments.output:
        parser.error("--check cannot be combined with --output")
    try:
        if arguments.check:
            checks_run = _run_behavior_checks()
            print(f"scalar duality checks passed: {checks_run}/3")
            return 0
        output = _resolve_output(arguments.output)
        _write_svg(output)
    except (AssertionError, OSError, ValueError) as error:
        print(f"Lagrangian duality figure generation failed: {error}", file=sys.stderr)
        return 1
    print(f"wrote {output.relative_to(REPOSITORY_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
