import random
import unittest
from fractions import Fraction

from rational_row import solve


class RationalRowTests(unittest.TestCase):
    def test_fraction_solution(self):
        result = solve([[2, 1], [1, -1]], [1, 0])
        self.assertEqual(result["particular"], ["1/3", "1/3"])
        self.assertEqual(result["status"], "unique")
        self.assertEqual(result["rref"], [["1", "0", "1/3"], ["0", "1", "1/3"]])

    def test_affine_space(self):
        result = solve([[1, 2, 3], [2, 4, 6]], ["1/5", "2/5"])
        self.assertEqual(result["particular"], ["1/5", "0", "0"])
        self.assertEqual(result["nullspace"], [["-2", "1", "0"], ["-3", "0", "1"]])

    def test_inconsistent_augmented_pivot(self):
        result = solve([[1, 2], [2, 4]], [1, 9])
        self.assertEqual(result["status"], "inconsistent")
        self.assertEqual(result["augmented_rank"], 2)
        self.assertEqual(result["rref"], [["1", "2", "0"], ["0", "0", "1"]])

    def test_operation_trace_replays(self):
        for seed in range(25):
            rng = random.Random(seed)
            rows = [[Fraction(rng.randint(-6, 6)) for _ in range(5)] for _ in range(6)]
            result = solve([r[:-1] for r in rows], [r[-1] for r in rows])
            for op in result["operations"]:
                if op["kind"] == "swap":
                    a, b = (i - 1 for i in op["rows"])
                    rows[a], rows[b] = rows[b], rows[a]
                elif op["kind"] == "scale":
                    at = op["row"] - 1
                    rows[at] = [v * Fraction(op["factor"]) for v in rows[at]]
                else:
                    at, source = op["target"] - 1, op["source"] - 1
                    rows[at] = [v + w * Fraction(op["factor"]) for v, w in zip(rows[at], rows[source])]
            self.assertEqual([list(map(str, row)) for row in rows], result["rref"])

    def test_invalid_domain_and_shape(self):
        for matrix, rhs in [([[0.25]], [1]), ([[True]], [0]), ([[1], [1, 2]], [0, 0]), ([[1]], [])]:
            with self.assertRaises(ValueError):
                solve(matrix, rhs)


if __name__ == "__main__":
    unittest.main()
