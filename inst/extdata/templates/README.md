# BreedReliabR operational input templates

These small files illustrate the hand-off from an upstream prediction model to BreedReliabR.

- `candidate_coefficients.csv` contains one row per candidate and one column per environmental-basis coefficient.
- `candidate_joint_PEV.rds` is the preferred binary format for the full candidate-major joint covariance.
- `target_environments.csv` contains TPE states in the same environmental basis plus weights.
- `training_environments.csv` contains the training environmental basis used by `br_support()`.

The source tree retains `candidate_joint_PEV.csv` and `generate_candidate_joint_PEV.R` as an auditable source representation. Before a 0.1.2 release is built, run `tools/u9-native-preflight.R` under native R to generate and verify `candidate_joint_PEV.rds`. The release gate must stop if that RDS is absent or invalid.

Do not manually reconstruct the full covariance from marginal standard errors or replace it with a diagonal matrix unless that diagonal matrix is genuinely the validated covariance supplied by the upstream model.
