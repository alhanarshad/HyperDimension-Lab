# Rational Row

Solve rectangular linear systems over the rationals and export the row operations that justify the result. There are no Python dependencies.

```sh
python rational_row.py example.json
python -m unittest -v
```

The input is a JSON object with `matrix` and `rhs`. Enter exact values as integers or strings such as `"-4/7"` and `"0.125"`. JSON floating-point numbers are rejected to avoid binary rounding.

The output reports the ranks of the coefficient and augmented matrices, pivot columns, and the augmented reduced row echelon form. For a consistent system it gives a particular solution and a basis for the nullspace, so the complete solution is `x = particular + c₁·basis₁ + …`. The operation log is ordered and uses one-based row indices. Use `--no-operations` to omit it.

Exact arithmetic is intended for small matrices and loses performance as coefficients grow. It is best suited to teaching, homework verification, or comparing a numerical solver against a small exact system.
