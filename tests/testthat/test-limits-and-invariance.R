test_that("large H makes M3 approach M1", {
  skip_on_cran()
  f <- make_fixture()
  a <- br_advance(f$pred, f$tpe, H = 1, k = 2, nsim = 4000, method = "M1", seed = 123)
  b <- br_advance(f$pred, f$tpe, H = 500, k = 2, nsim = 4000, method = "M3", seed = 123)
  expect_lt(max(abs(a$candidates$p_advance - b$candidates$p_advance)), 0.04)
})

test_that("candidate permutation preserves probabilities after matching IDs", {
  f <- make_fixture()
  a <- br_advance(f$pred, f$tpe, H = 5, k = 2, nsim = 2500, method = "M3", seed = 321)

  ord <- c(3,1,4,2)
  p <- ncol(f$pred$coef_mean)
  coef_idx <- unlist(lapply(ord, function(i) ((i-1)*p+1):(i*p)))
  pred2 <- br_prediction(
    candidates = f$pred$candidates[ord],
    coef_mean = f$pred$coef_mean[ord, , drop = FALSE],
    coef_vcov = f$pred$coef_vcov[coef_idx, coef_idx, drop = FALSE]
  )
  b <- br_advance(pred2, f$tpe, H = 5, k = 2, nsim = 2500, method = "M3", seed = 321)
  pa <- setNames(a$candidates$p_advance, a$candidates$candidate)
  pb <- setNames(b$candidates$p_advance, b$candidates$candidate)
  expect_equal(pa[sort(names(pa))], pb[sort(names(pb))], tolerance = 0.035)
})
