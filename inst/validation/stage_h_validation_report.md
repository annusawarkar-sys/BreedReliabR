# Stage H validation report

## Status

A source-level R prototype of the four locked core functions was created:

- `br_prediction()`
- `br_tpe()`
- `br_omega()`
- `br_advance()`

The execution environment did not contain an R runtime, so `R CMD check` and `testthat` could not be executed here. The same mathematical kernel was independently implemented in Python and used to verify the numerical identities and limiting cases that the R tests encode.

## Numerical results

- Advancement-probability invariant: sum of candidate advancement probabilities = **2.000000000000** for `k = 2`.
- Reproducibility with a fixed random seed: maximum absolute difference = **0.000000000000**.
- Zero environmental variation: M3 and M1 maximum absolute probability difference = **0.000000000000**.
- Zero prediction uncertainty: M3 and M2 maximum absolute probability difference = **0.000000000000**.
- Both uncertainties zero: all four methods collapsed to the same decision, maximum difference = **0.000000000000**.
- Large-H convergence: maximum absolute M3–M1 difference declined from **0.0118** at H=5 to **0.0007** at H=500.
- Analytic joint variance for the one-candidate test = **0.226000**.
- Monte Carlo variance from 300,000 draws = **0.226925**.
- Relative analytic-versus-Monte-Carlo discrepancy = **0.4093%**.

## Interpretation

The core covariance propagation is numerically consistent with the Stage C–F mathematics. The limiting cases behave correctly, and the identity `sum_i p_i^A = k` is preserved by construction.

## Remaining requirement before Stage H can be called fully complete

The included `testthat` suite must be run in an R-enabled environment, followed by `R CMD check`. No release, manuscript result, or CRAN submission should rely on this prototype until those native-R checks pass.
