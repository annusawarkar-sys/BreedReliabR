test_that("environmental variance scales as 1/H", {
  f <- make_fixture()
  o <- br_omega(f$pred, f$tpe, H = c(1, 5, 10))
  z <- o$candidate[o$candidate$candidate == "G1", ]
  e1 <- z$env_var[z$H == 1]
  expect_equal(z$env_var[z$H == 5], e1 / 5, tolerance = 1e-12)
  expect_equal(z$env_var[z$H == 10], e1 / 10, tolerance = 1e-12)
})

test_that("zero environmental variation gives omega zero", {
  f <- make_fixture(zero_env = TRUE)
  o <- br_omega(f$pred, f$tpe, H = c(1,5))
  expect_equal(o$candidate$env_var, rep(0, nrow(o$candidate)), tolerance = 1e-12)
  expect_equal(o$candidate$omega, rep(0, nrow(o$candidate)), tolerance = 1e-12)
})
