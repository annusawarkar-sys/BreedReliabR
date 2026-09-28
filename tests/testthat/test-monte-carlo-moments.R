test_that("joint Monte Carlo variance matches analytic decomposition", {
  skip_on_cran()
  # One candidate, intercept + stress slope.
  mu <- matrix(c(1.0, 0.4), nrow = 1)
  colnames(mu) <- c("intercept", "stress")
  P <- matrix(c(0.20, 0.03, 0.03, 0.10), 2, 2)
  pred <- br_prediction("G1", mu, P)
  X <- rbind(c(1,-1), c(1,0), c(1,1))
  colnames(X) <- c("intercept", "stress")
  tpe <- br_tpe(X, c(0.25,0.5,0.25))
  om <- br_omega(pred, tpe, H = 5)$candidate
  analytic <- om$pred_var + om$env_var

  set.seed(42)
  S <- 30000
  # Recreate the core joint draws with package internals visible via ::: only in tests.
  B <- BreedReliabR:::.br_rmvnorm(S, c(t(mu)), P)
  E <- BreedReliabR:::.br_sample_env_mean(tpe, 5, S)
  U <- rowSums(B * E)
  expect_equal(stats::var(U), analytic, tolerance = 0.03)
})
