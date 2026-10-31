# BreedReliabR operational input templates

These small files illustrate the hand-off from an upstream prediction model to BreedReliabR.

- `candidate_coefficients.csv` contains one row per candidate and one column per environmental-basis coefficient.
- `candidate_joint_PEV.rds` is the preferred binary format for the full candidate-major joint covariance.
- `target_environments.csv` contains TPE states in the same environmental basis plus weights.
- `training_environments.csv` contains the training environmental basis used by `br_support()`.

The release includes the canonical `candidate_joint_PEV.rds`. The source tree also retains `candidate_joint_PEV.csv` and `generate_candidate_joint_PEV.R` as an auditable source representation. `tools/u9-native-preflight.R` regenerates and verifies the RDS during release validation.

Do not manually reconstruct the full covariance from marginal standard errors or replace it with a diagonal matrix unless that diagonal matrix is genuinely the validated covariance supplied by the upstream model.
