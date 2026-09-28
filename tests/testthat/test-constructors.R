test_that("constructors validate and normalize", {
  f <- make_fixture()
  expect_s3_class(f$pred, "br_prediction")
  expect_s3_class(f$tpe, "br_tpe")
  expect_equal(sum(f$tpe$weights), 1)

  X <- f$tpe$basis
  t2 <- br_tpe(X, c(25, 50, 25))
  expect_equal(t2$weights, f$tpe$weights)
  t3 <- br_tpe(X, c(5e307, 1e308, 5e307))
  expect_equal(t3$weights, f$tpe$weights)
  t4 <- br_tpe(X, c(5e-300, 1e-299, 5e-300))
  expect_equal(t4$weights, f$tpe$weights)
  a <- br_advance(f$pred, f$tpe, H = 4, k = 2, nsim = 300,
                  method = "M3", seed = 91)
  b <- br_advance(f$pred, t2, H = 4, k = 2, nsim = 300,
                  method = "M3", seed = 91)
  expect_identical(a$candidates$p_advance, b$candidates$p_advance)
})

test_that("non-PSD covariance is rejected", {
  mu <- matrix(c(1, 0, 0.8, 0.1), nrow = 2, byrow = TRUE)
  colnames(mu) <- c("intercept", "stress")
  P <- diag(4)
  P[1,2] <- P[2,1] <- 2
  expect_error(br_prediction(c("A", "B"), mu, P), "positive semidefinite")
})

test_that("public numerical tolerances are finite non-negative scalars", {
  f <- make_fixture()
  expect_error(br_prediction(f$pred$candidates, f$pred$coef_mean,
    f$pred$coef_vcov, tol = -1), "tol")
  expect_error(br_prediction(f$pred$candidates, f$pred$coef_mean,
    f$pred$coef_vcov, tol = Inf), "tol")
  expect_error(br_advance(f$pred, f$tpe, k = 2, tol = "1e-8"), "tol")
  expect_error(br_prediction(f$pred$candidates, f$pred$coef_mean + 1i,
    f$pred$coef_vcov), "real numeric")
  expect_error(br_tpe(f$tpe$basis, weights = c(1 + 1i, 1, 1)), "real numeric")
})
