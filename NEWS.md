# BreedReliabR 0.1.1

* Add Santosh Patil as a package author for substantial R programming and coding
  contribution. Ashutosh Sawarkar remains the sole maintainer.
* Update the maintainer email and add author contact and ORCID metadata.
* Metadata-only release; no statistical, API, or package behaviour changes.

# BreedReliabR 0.1.0

## First research release

* Freeze the seven-function research API for externally supplied prediction
  means and full joint prediction-error covariance.
* Provide M0--M3 comparison, expected selected-set reliability, candidate-level
  advancement probabilities, and the relative uncertainty diagnostic Omega(H).
* Add geometric target-environment support diagnostics and an H-curve workflow.
* Clarify assumptions, fixed-k interpretation, Monte Carlo error, RNG behavior,
  candidate-major covariance ordering, and the limits of geometric support.
* Retain the simulated maize data and add a reproducible methods/empirical
  validation vignette. No G2F raw data are included.
* External evidence: 2024 validation and forward year-held-out 2022 replication
  found poor absolute calibration, M2 worst, a small M3 Brier advantage over M1,
  and overpredicted selected-set reliability. The corrected L3a 2022 baseline
  is canonical; the original denominator error and correction are retained in
  the separate audit archive.

Known limitations: probabilities are conditional on the supplied upstream
predictive distribution and target-environment specification. Empirical
calibration is poor in the two validation settings; software release readiness
does not imply calibrated probabilities or guaranteed genetic gain.

# BreedReliabR 0.0.3

* Added br_compare() and br_curve() as wrappers around the unchanged H2 core.
* Added range and standardized nearest-environment support diagnostics.
* Added compact S3 print, summary and plot methods for the new result classes.
* Added entirely simulated maize data, a reproducible generation script, and an
  executable end-to-end vignette with explicit fit-import and calibration limits.
* Added executable examples to all principal public functions and regression tests.
* Clarified expected-fraction set reliability, Monte Carlo limitations and fixed
  TPE assumptions. No core mathematics or H2 tests were changed.
