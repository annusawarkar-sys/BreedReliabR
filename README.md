# BreedReliabR 0.1.2 development candidate

BreedReliabR is a model-agnostic decision-reliability layer for **fixed-k genotype advancement**. It starts after an external genomic or genotype-by-environment prediction model has produced candidate environmental-response coefficient means and their **full joint prediction-error covariance**.

BreedReliabR does **not** fit the genomic prediction model itself. It propagates the uncertainty supplied by that model together with finite representation of a user-specified target population of environments (TPE).

## Where should I start?

### I have ordinary breeding data

If you currently have phenotype/MET data, SNP markers or pedigree information, and environmental covariates, start with the vignette **From breeding data to BreedReliabR: start here**. It shows why raw breeding data are not direct BreedReliabR inputs and demonstrates the hand-off using a transparent reaction-norm example.

### I have a fitted genomic or GxE model

You need to obtain:

1. candidate environmental-response coefficient means, and
2. their full joint prediction-error covariance.

The vignette **Genomic GxE prediction to BreedReliabR** shows this hand-off with phenotyped training genotypes and separate unphenotyped candidates.

### I use another prediction model

The vignette **Using BreedReliabR with different prediction models** explains how GBLUP, RR-BLUP, random regression, Bayesian models, factor-analytic GxE, direct environment-state predictions, and other upstream approaches can be assessed against the same interface. It distinguishes conceptual compatibility from software-specific integrations that have actually been validated.

### I already have BreedReliabR-ready inputs

For `n` candidates and `p` environmental-basis coefficients, prepare:

- `coef_mean`: `n x p` candidate coefficient means;
- `coef_vcov`: full `np x np` joint covariance in candidate-major order;
- TPE states expressed in exactly the same environmental basis;
- TPE weights;
- the fixed number `k` of candidates to advance; and
- the future environmental representation `H`.

Run the structural preflight helper before constructing package objects:

```r
check <- br_check_inputs(
  candidates = candidate_ids,
  coef_mean = coef_mean,
  coef_vcov = coef_vcov,
  tpe_basis = tpe_basis,
  tpe_weights = tpe_weights,
  training_basis = training_basis,
  k = 10,
  H = 5
)

check
```

`br_check_inputs()` diagnoses dimensions, labels, symmetry, positive-semidefinite behaviour, basis compatibility and decision settings. It does not repair inputs and does not validate the scientific adequacy of the upstream model or TPE.

## BreedReliabR begins here

Once valid model outputs are available, the analysis is compact:

```r
library(BreedReliabR)

prediction <- br_prediction(
  candidates = candidate_ids,
  coef_mean = coef_mean,
  coef_vcov = coef_vcov
)

tpe <- br_tpe(
  basis = tpe_basis,
  weights = tpe_weights
)

result <- br_advance(
  prediction = prediction,
  tpe = tpe,
  H = 5,
  k = 10,
  nsim = 10000,
  method = "M3",
  seed = 123
)
```

## Operational workflow

```text
BREEDING PROGRAMME DATA
phenotypes / MET + markers or pedigree + environmental covariates
        |
        v
UPSTREAM PREDICTION MODEL
GBLUP / genomic GxE / reaction norm / random regression / other model
        |
        +---------------------------+
        |                           |
        v                           v
candidate coefficient means     full joint candidate PEV
        n x p                        np x np
        |                           |
        +-------------+-------------+
                      |
                      v
              br_check_inputs()
                      |
                      v
             br_prediction()
                      +
                  br_tpe()
                      |
                      v
 br_support() / br_omega() / br_compare() / br_advance() / br_curve()
                      |
                      v
            BREEDER ADVANCEMENT DECISION
```

The TPE is specified separately by the breeder or researcher. It is not automatically produced by the genomic model.

## What the methods compare

- **M0** ranks point expected merit and selects the top `k`. Its 0/1 membership values are deterministic selection indicators; M0 does not estimate probabilistic reliability.
- **M1** propagates prediction uncertainty while treating the specified TPE mean as fixed.
- **M2** propagates finite-TPE environmental uncertainty while holding candidate coefficients at their means.
- **M3** propagates both uncertainty sources jointly.

M0-M3 use the same prediction object and TPE. They are uncertainty formulations, not different genomic models.

For candidate `i`, `p_advance` is the conditional probability that the candidate belongs to the selected top `k` under the supplied predictive distribution, TPE, `H`, and uncertainty formulation. For M1-M3, candidate advancement probabilities sum to `k` up to numerical precision because exactly `k` candidates are selected in every simulated decision world.

Selected-set reliability is an **expected retained fraction**, not the probability of recovering the complete set.

`br_omega()` reports Omega(H), the ratio of finite-TPE environmental variance to prediction variance. Omega is a relative uncertainty diagnostic, not a probability, genetic gain, selection gain, or universal threshold.

`br_support()` reports geometric environmental-support diagnostics. It cannot establish biological validity, prediction accuracy, or calibration.

## Candidate-major covariance ordering

For candidates `G01`, `G02`, ... and basis terms `intercept`, `PC1`, `PC2`, the full covariance must correspond to:

```text
G01__intercept
G01__PC1
G01__PC2
G02__intercept
G02__PC1
G02__PC2
...
```

Marginal standard errors are not an adequate substitute for the full covariance. Do not construct a diagonal covariance unless that is genuinely the validated covariance implied by the upstream prediction model.

## Installation

The current CRAN release remains 0.1.1 until version 0.1.2 is formally released:

```r
install.packages("BreedReliabR")
library(BreedReliabR)
```

This source tree is the 0.1.2 development candidate.

## Included simulated maize example

The original compact maize example remains available and the statistical core is unchanged:

```r
library(BreedReliabR)
data(maize_demo)

prediction <- do.call(br_prediction, maize_demo$prediction_inputs)
tpe <- br_tpe(
  maize_demo$tpe_basis,
  maize_demo$tpe_states$weight
)

support <- br_support(tpe, maize_demo$training_basis)
omega <- br_omega(prediction, tpe, H = c(1, 3, 5, 10, 21))
comparison <- br_compare(
  prediction, tpe, H = 5, k = 3,
  nsim = 10000, seed = 410
)
```

## Assumptions and limitations

Results are conditional on the upstream coefficient means, supplied full covariance, environmental basis, TPE states and weights, fixed-k decision rule, and `H`. The preflight helper can establish structural compatibility but cannot establish that the upstream predictive distribution is correctly specified or calibrated.

`br_tpe()` weights encode an assumed target distribution and are not automatically production-area weights. `H` is the number of independent future draws from the specified TPE whose average represents the future environmental target under the current formulation; it is not the number of training environments.

A low Monte Carlo standard error quantifies simulation precision only. Increasing `nsim` cannot correct biased predictions, an inadequate covariance model, an inappropriate TPE, or biological extrapolation.

The package currently uses a joint Gaussian coefficient distribution. "Model-agnostic" refers to the external model-fitting method, not to absence of distributional assumptions in the BreedReliabR propagation layer.

## Empirical evidence

The project evaluated a frozen 2024 maize external-validation network and a strictly forward, year-held-out 2022 analysis. Absolute probability calibration was poor in both validation settings. M2 performed worst; M3 had only a small Brier advantage over M1; probability methods were worse than prevalence-only forecasts; and predicted selected-set reliability was substantially overoptimistic.

These findings are an important claim boundary: correct uncertainty propagation does not itself guarantee calibrated real-world advancement probabilities when the upstream predictive distribution is inadequate. There is no evidence that M3 universally produces greater genetic gain.

## Reproducibility and citation

Before release, run the complete package test suite, render all vignettes, and run `R CMD check --as-cran` on the source package. The compact simulated data and tests are offline. External G2F raw data are not bundled.

To cite the software, use:

```r
citation("BreedReliabR")
```

CRAN package DOI: `10.32614/CRAN.package.BreedReliabR`.
