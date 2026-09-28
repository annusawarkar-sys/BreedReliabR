# BreedReliabR 0.1.0

BreedReliabR translates externally fitted genotype-by-environment predictions into **conditional advancement probabilities** under a fixed-$k$ selection rule. It is designed for cases where prediction accuracy alone does not answer the breeding decision: two candidates with similar predicted merit can have different advancement probabilities when their predictive uncertainty differs, and a finite target population of environments adds another source of uncertainty.

The package does not fit genomic models. It accepts environmental-basis coefficient means and the **full joint prediction-error covariance** from an upstream model that has been independently fitted and validated. Marginal standard errors are not an adequate substitute.

## What the methods compare

- **M0:** ranks point expected merit and selects the top (k). Its 0/1 selection indicators are deterministic; M0 does not estimate probabilities or selected-set reliability.
- **M1:** propagates genomic prediction uncertainty, treating the specified TPE mean as fixed.
- **M2:** propagates finite-TPE environmental uncertainty while holding candidate coefficients at their means.
- **M3:** propagates both uncertainty sources jointly.

M0–M3 use the same predictive means and target-environment specification. They are uncertainty formulations, not alternative genomic prediction models.

For candidate $i$, $p_i^A$ is the model-based probability of appearing in the selected $k$ under the supplied predictive distribution, TPE, and number $H$ of future independent TPE draws. The probabilities satisfy $\sum_i p_i^A=k$ up to Monte Carlo error. For a selected set $S$, $R_{set}=k^{-1}\sum_{i\in S}p_i^A$ is its expected retained fraction. It is not the probability of recovering the exact set.

`br_omega()` reports $\Omega(H)$, the ratio of finite-TPE environmental variance to prediction variance under the specified formulation. It is a relative uncertainty diagnostic, not a probability and not a universal decision threshold.

## Installation

Install the source package locally with R:

```r
install.packages("BreedReliabR_0.1.0.tar.gz", repos = NULL, type = "source")
```

The package uses base/recommended R packages at runtime. `testthat`, `knitr`, and `rmarkdown` are suggested for tests and vignettes. It does not require `sommer` or another genomic model-fitting package.

## Small simulated example

The bundled maize example is simulated and is not a fitted empirical dataset:

```r
library(BreedReliabR)
data(maize_demo)
prediction <- do.call(br_prediction, maize_demo$prediction_inputs)
tpe <- br_tpe(maize_demo$tpe_basis, maize_demo$tpe_states$weight)

support <- br_support(tpe, maize_demo$training_basis)
omega <- br_omega(prediction, tpe, H = c(1, 3, 5, 10, 21))
comparison <- br_compare(prediction, tpe, H = 5, k = 3,
                         nsim = 10000, seed = 410)
curve <- br_curve(prediction, tpe, H = c(1, 3, 5, 10), k = 3,
                  nsim = 10000, seed = 410)
```

## Workflow

```text
external genomic model
        ↓
coefficient means + full joint PEV
        ↓
br_prediction() + br_tpe()
        ↓
br_support() → br_omega() → br_compare()/br_advance() → br_curve()
        ↓
external validation of frozen probabilities and decisions
```

## Assumptions and limitations

Results are conditional on the upstream coefficient means, the supplied full covariance, the environmental basis, TPE states and weights, the fixed-$k$ decision rule, and $H$. The package does not validate those inputs or account for uncertainty omitted by the upstream model. `br_tpe()` weights encode an assumed target distribution; they are not automatically production-area weights. `br_support()` describes marginal ranges and nearest-neighbour distances in the supplied environmental basis; geometric support does not prove biological validity or prediction calibration. A low Monte Carlo standard error measures simulation error only, not biological or external-reference uncertainty. Increase `nsim` when candidate probabilities near the selection boundary need greater precision; there is no universal simulation count.

`br_curve()` reports each requested $H$ independently and does not impose monotonicity. The interpretation of $H$ is the number of future independent TPE draws under the reference formulation. The package preserves full cross-candidate and cross-coefficient covariance; dense covariance inputs can require substantial memory as candidate count grows.

## Empirical evidence

The project evaluated a frozen 2024 maize external-validation network and a strictly forward, year-held-out 2022 analysis. The corrected 2022 candidate-level Brier audit uses 548 candidates with estimable outcomes (one row per candidate and method); its original prevalence denominator error is preserved and documented in the reproducibility archive. Across both analyses, absolute probability calibration was poor, M2 performed worst, and M3 had slightly lower Brier loss than M1. Probability methods were worse than prevalence-only forecasts, and predicted selected-set reliability was substantially overoptimistic. Merit alignment was stronger descriptively among candidates with historical phenotype information; that association is not causal evidence. There is no evidence that M3 guarantees higher genetic gain.

The retained simulation evidence checks mathematical identities and software invariants, including fixed-k probability sums and limiting cases. It is not a broad generator-based calibration study; empirical calibration claims are based on the two external validation analyses above.

For 2022, the data are a year-held-out validation derived from a later authoritative G2F release. This is not an exact recreation of the separate official 2022 competition test design. These results delimit the empirical claim: correct uncertainty propagation does not by itself guarantee calibrated real-world advancement probabilities when the upstream predictive distribution is inadequate.

## Reproducibility and citation

Run `R CMD check --as-cran` on the source package. The compact simulated data and tests are offline. The external G2F data are not bundled; acquisition instructions, provenance, expected hashes, scripts, frozen derived outputs where allowed, and the corrected L3a audit trail are maintained in the separate Stage M reproducibility archive.

To cite the software, use `citation("BreedReliabR")`. The package has no DOI or published manuscript citation at this release. Do not infer CRAN acceptance from the version number or validation report.
