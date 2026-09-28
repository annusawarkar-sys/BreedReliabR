# Entirely synthetic illustration: no observations or fitted genomic model.
# Run from the editable package root. Fixed seed and construction are auditable.
set.seed(260926)
training <- data.frame(environment = sprintf("TR%02d", 1:12),
  flowering_water_deficit = c(.10,.15,.20,.25,.30,.35,.40,.45,.50,.55,.60,.65),
  hot_days_flowering = c(2,5,1,7,3,9,5,11,7,13,9,15))
basis <- function(d) cbind(intercept = 1,
  water = (d$flowering_water_deficit - .35) / .20,
  heat = (d$hot_days_flowering - 7) / 5)
training_basis <- basis(training)
states <- data.frame(state_id = c("cool_wet", "typical", "dry", "hot_dry", "extreme"),
  flowering_water_deficit = c(.15,.35,.55,.60,.80),
  hot_days_flowering = c(2,7,9,14,20), weight = c(.15,.40,.25,.15,.05))
ids <- sprintf("MZ%02d", 1:8)
means <- cbind(intercept = c(9.5,9.35,9.2,9.05,8.9,8.8,8.65,8.5),
  water = c(-1.25,-.9,-.6,-1.1,-.45,-.75,-.35,-.5),
  heat = c(-.65,-.5,-.55,-.35,-.4,-.3,-.2,-.25))
rownames(means) <- ids
# Correlated candidate and coefficient uncertainty; Kronecker order is candidate-major.
candidate_cor <- .25^abs(outer(1:8, 1:8, `-`))
term_cov <- diag(c(.30,.18,.12)^2)
term_cov[1,2] <- term_cov[2,1] <- -.012
vcov <- kronecker(candidate_cor, term_cov)
dimnames(vcov) <- rep(list(as.vector(t(outer(ids, colnames(means), paste, sep = ":")))), 2)
training_genotypes <- sprintf("TG%02d", 1:10)
truth <- cbind(stats::rnorm(10, 8.8, .6), stats::rnorm(10, -.8, .18),
  stats::rnorm(10, -.4, .10))
phenotypes <- expand.grid(genotype = training_genotypes,
  environment = training$environment, replicate = 1:2, stringsAsFactors = FALSE)
i <- match(phenotypes$genotype, training_genotypes)
j <- match(phenotypes$environment, training$environment)
phenotypes$yield_t_ha <- rowSums(truth[i, ] * training_basis[j, ]) +
  stats::rnorm(nrow(phenotypes), 0, .45)
maize_demo <- list(training_environments = training,
  training_basis = training_basis, training_phenotypes = phenotypes,
  candidates = data.frame(candidate = ids, phenotyped = FALSE),
  prediction_inputs = list(candidates = ids, coef_mean = means, coef_vcov = vcov,
    source = "Simulated fit-import inputs; not estimated from training phenotypes",
    metadata = list(simulated = TRUE, response_units = "t/ha")),
  tpe_states = states, tpe_basis = basis(states),
  provenance = list(simulated = TRUE, seed = 260926L,
    explanation = paste("Synthetic maize yield scenario. Prediction inputs are stipulated,",
      "not fitted to the illustrative phenotypes. No empirical calibration is implied.")))
save(maize_demo, file = "data/maize_demo.rda", compress = "xz", version = 2)
