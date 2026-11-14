"""Exact Gaussian elimination for systems Ax = b."""
import argparse
import json
import sys
from fractions import Fraction
from pathlib import Path


def fraction(value):
    if isinstance(value, bool) or not isinstance(value, (int, str, Fraction)):
        raise ValueError("Use integers or fraction/decimal strings for exact inputs.")
    return Fraction(value)


def solve(matrix, rhs):
    """Return the RREF, elementary operations, and an affine solution set."""
    if not matrix or not isinstance(matrix[0], (list, tuple)) or not matrix[0]:
        raise ValueError("The coefficient matrix must have at least one row and column.")
    width = len(matrix[0])
    if len(rhs) != len(matrix) or any(not isinstance(row, (list, tuple)) or len(row) != width for row in matrix):
        raise ValueError("All coefficient rows must have equal width and match the right-hand side.")
    rows = [[*map(fraction, row), fraction(b)] for row, b in zip(matrix, rhs)]
    height = len(rows)
    pivots, operations = [], []
    for column in range(width):
        target = len(pivots)
        candidates = [i for i in range(target, height) if rows[i][column]]
        if not candidates:
            continue
        source = min(candidates, key=lambda i: (rows[i][column].numerator.bit_length()
                                               + rows[i][column].denominator.bit_length(), i))
        if source != target:
            rows[source], rows[target] = rows[target], rows[source]
            operations.append({"kind": "swap", "rows": [source + 1, target + 1]})
        factor = 1 / rows[target][column]
        if factor != 1:
            rows[target] = [x * factor for x in rows[target]]
            operations.append({"kind": "scale", "row": target + 1, "factor": str(factor)})
        for index, row in enumerate(rows):
            if index == target or not row[column]:
                continue
            factor = -row[column]
            rows[index] = [x + factor * y for x, y in zip(row, rows[target])]
            operations.append({"kind": "add", "target": index + 1, "source": target + 1, "factor": str(factor)})
        pivots.append(column)

    rank = len(pivots)
    inconsistent = any(not any(row[:-1]) and row[-1] for row in rows)
    if inconsistent:
        target = rank
        source = next(i for i in range(rank, height) if rows[i][-1])
        if source != target:
            rows[source], rows[target] = rows[target], rows[source]
            operations.append({"kind": "swap", "rows": [source + 1, target + 1]})
        factor = 1 / rows[target][-1]
        if factor != 1:
            rows[target] = [x * factor for x in rows[target]]
            operations.append({"kind": "scale", "row": target + 1, "factor": str(factor)})
        for index, row in enumerate(rows):
            if index != target and row[-1]:
                factor = -row[-1]
                rows[index] = [x + factor * y for x, y in zip(row, rows[target])]
                operations.append({"kind": "add", "target": index + 1, "source": target + 1, "factor": str(factor)})
    result = {"rank": rank, "augmented_rank": rank + int(inconsistent),
              "pivots": [i + 1 for i in pivots],
              "rref": [list(map(str, row)) for row in rows], "operations": operations}
    if inconsistent:
        return {**result, "status": "inconsistent", "particular": None, "nullspace": None}

    particular = [Fraction(0)] * width
    for index, column in enumerate(pivots):
        particular[column] = rows[index][-1]
    basis = []
    for free in range(width):
        if free not in pivots:
            vector = [Fraction(0)] * width
            vector[free] = Fraction(1)
            for index, column in enumerate(pivots):
                vector[column] = -rows[index][free]
            basis.append(list(map(str, vector)))
    return {**result, "status": "underdetermined" if basis else "unique",
            "particular": list(map(str, particular)), "nullspace": basis}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="JSON file with matrix and rhs, or - for stdin")
    parser.add_argument("--no-operations", action="store_true", help="Omit the elementary row-operation log")
    args = parser.parse_args()
    try:
        source = sys.stdin.read() if args.input == "-" else Path(args.input).read_text(encoding="utf-8")
        problem = json.loads(source)
        result = solve(problem["matrix"], problem["rhs"])
    except (OSError, TypeError, KeyError, ValueError, ZeroDivisionError) as error:
        parser.exit(2, f"rational-row: {error}\n")
    if args.no_operations:
        result.pop("operations")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
