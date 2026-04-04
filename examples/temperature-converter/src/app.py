"""
Temperature converter — toy project for agent sandbox testing.

Usage:
    uv run src/app.py 100 C F      # 100°C → 212.0°F
    uv run src/app.py 72  F C      # 72°F  → 22.22°C
    uv run src/app.py 300 K C      # 300K  → 26.85°C
"""

import sys

from rich.console import Console
from rich.markdown import Markdown

UNIT_NAMES = {"C": "Celsius", "F": "Fahrenheit", "K": "Kelvin"}

console = Console()


def convert(value: float, from_unit: str, to_unit: str) -> float:
    """Convert between Celsius (C), Fahrenheit (F), and Kelvin (K)."""
    # Normalise to Celsius first
    if from_unit == "C":
        celsius = value
    elif from_unit == "F":
        celsius = (value - 32) * 5 / 9
    elif from_unit == "K":
        celsius = value - 273.15
    else:
        raise ValueError(f"Unknown unit: {from_unit}")

    # Convert from Celsius to target
    if to_unit == "C":
        return celsius
    elif to_unit == "F":
        return celsius * 9 / 5 + 32
    elif to_unit == "K":
        return celsius + 273.15
    else:
        raise ValueError(f"Unknown unit: {to_unit}")


def format_result(value: float, from_unit: str, to_unit: str, result: float) -> str:
    """Build a Markdown string summarising the conversion."""
    from_name = UNIT_NAMES.get(from_unit, from_unit)
    to_name = UNIT_NAMES.get(to_unit, to_unit)
    return (
        f"## Temperature Conversion\n\n"
        f"| Field | Value |\n"
        f"|-------|-------|\n"
        f"| **Input** | {value:.2f}° {from_name} |\n"
        f"| **Output** | {result:.2f}° {to_name} |\n"
    )


def main() -> None:
    if len(sys.argv) != 4:
        console.print(Markdown(f"```\n{__doc__.strip()}\n```"))
        sys.exit(1)

    value = float(sys.argv[1])
    from_unit = sys.argv[2].upper()
    to_unit = sys.argv[3].upper()

    result = convert(value, from_unit, to_unit)
    md = format_result(value, from_unit, to_unit, result)
    console.print(Markdown(md))


if __name__ == "__main__":
    main()
