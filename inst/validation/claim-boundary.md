# BreedReliabR claim boundary — version 0.1.0

## Claims supported by the implementation and locked validation record

BreedReliabR propagates supplied genomic prediction uncertainty and finite-TPE
environmental uncertainty jointly into model-based advancement probabilities
under a fixed-k decision rule. It retains the supplied full covariance across
candidate coefficients and candidates, estimates expected selected-set
reliability, reports the prediction-versus-environment variance ratio
Omega(H), and provides geometric support diagnostics. M0-M3 compare uncertainty
formulations using one predictive model and one TPE. The software passed native
R simulation/invariant checks and the H2/Stage I package checks. Frozen
prediction outputs were also evaluated against the 2024 G2F network and in a
forward year-held-out 2022 analysis; the corrected 2022 prevalence audit is
the canonical source for that result. The retained simulation evidence covers
mathematical identities and software invariants; it is not a broad
generator-based calibration study.

## Claims that are not supported

Do not claim general empirical calibration, guaranteed improvement in genetic
gain, universal superiority of M3 over M1, or a universal Omega threshold.
Geometric TPE support does not establish biological validity. Selected-set
reliability is not exact-set recovery probability. Monte Carlo standard errors
measure simulation error, not biological uncertainty. The package does not fit
genomic models or validate upstream predictions. The 2022 analysis is a
year-held-out analysis using a later authoritative release, not an exact
reconstruction of the separate official 2022 competition test design.

## Empirical conclusion to preserve

M3 consistently reduced Brier loss slightly relative to M1 in both 2024 and
2022, but absolute calibration remained poor, M2 was worst, and predicted
selected-set reliability was substantially overoptimistic. The 2022 conclusion
uses the corrected candidate-level prevalence baseline from Stage L3a. Correct
uncertainty propagation does not by itself guarantee calibrated real-world
advancement probabilities when the upstream predictive distribution is
inadequate.
