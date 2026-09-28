test_that("advancement probability invariant is exact up to floating point", {
  f <- make_fixture()
  a <- br_advance(f$pred, f$tpe, H = 5, k = 2, nsim = 2000, method = "M3", seed = 11)
  expect_equal(sum(a$candidates$p_advance), 2, tolerance = 1e-12)
  expect_equal(a$probability_sum, 2, tolerance = 1e-12)
})

test_that("same seed reproduces M3", {
  f <- make_fixture()
  a <- br_advance(f$pred, f$tpe, H = 5, k = 2, nsim = 1200, method = "M3", seed = 99)
  b <- br_advance(f$pred, f$tpe, H = 5, k = 2, nsim = 1200, method = "M3", seed = 99)
  expect_equal(a$candidates$p_advance, b$candidates$p_advance)
})

test_that("zero environmental variation makes M3 equal M1", {
  f <- make_fixture(zero_env = TRUE)
  a <- br_advance(f$pred, f$tpe, H = 3, k = 2, nsim = 2000, method = "M1", seed = 7)
  b <- br_advance(f$pred, f$tpe, H = 3, k = 2, nsim = 2000, method = "M3", seed = 7)
  expect_equal(a$candidates$p_advance, b$candidates$p_advance)
})

test_that("zero prediction uncertainty makes M3 equal M2", {
  f <- make_fixture(zero_pred = TRUE)
  a <- br_advance(f$pred, f$tpe, H = 3, k = 2, nsim = 2000, method = "M2", seed = 8)
  b <- br_advance(f$pred, f$tpe, H = 3, k = 2, nsim = 2000, method = "M3", seed = 8)
  expect_equal(a$candidates$p_advance, b$candidates$p_advance)
})

test_that("both uncertainties zero collapse all methods", {
  f <- make_fixture(zero_pred = TRUE, zero_env = TRUE)
  res <- lapply(c("M0","M1","M2","M3"), function(m) {
    br_advance(f$pred, f$tpe, H = 4, k = 2, nsim = 500, method = m, seed = 10)$candidates$p_advance
  })
  for (j in 2:4) expect_equal(res[[1]], res[[j]])
})
