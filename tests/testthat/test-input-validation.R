test_that("whole-number arguments are enforced", {
  f <- make_fixture()
  expect_error(br_advance(f$pred, f$tpe, H = 2.5, k = 2, nsim = 100, method = "M3"), "whole number")
  expect_error(br_advance(f$pred, f$tpe, H = 2, k = 1.5, nsim = 100, method = "M3"), "whole number")
  expect_error(br_advance(f$pred, f$tpe, H = 2, k = 2, nsim = 100.5, method = "M3"), "whole number")
  expect_error(br_omega(f$pred, f$tpe, H = c(1, 2.5)), "whole numbers")
  expect_error(br_advance(f$pred, f$tpe, H = "5", k = 2), "H")
  expect_error(br_advance(f$pred, f$tpe, H = 5, k = 2, nsim = "100"), "nsim")
  expect_error(br_omega(f$pred, f$tpe, H = "2"), "H")
  expect_error(br_advance(f$pred, f$tpe, H = 3e9, k = 2), "H")
  expect_error(br_omega(f$pred, f$tpe, H = 3e9), "H")
})

test_that("empty environmental names and state identifiers are rejected", {
  f <- make_fixture()
  X <- f$tpe$basis
  colnames(X)[2] <- ""
  expect_error(br_tpe(X), "unique column names")

  X <- f$tpe$basis
  expect_error(br_tpe(X, state_id = c("E1", "", "E3")), "uniquely identify")
})

test_that("M0 does not claim probabilistic reliability", {
  f <- make_fixture()
  a <- br_advance(f$pred, f$tpe, H = 5, k = 2, method = "M0")
  expect_true(is.na(a$expected_merit_set_reliability))
  expect_true(is.na(a$probability_set_reliability))
  expect_equal(sum(a$candidates$p_advance), 2)
  expect_equal(sort(a$candidates$p_advance), c(0, 0, 1, 1))
  expect_match(paste(capture.output(print(a)), collapse = " "), "not estimated by M0")
})

test_that("advancing every candidate gives unit inclusion probabilities", {
  f <- make_fixture()
  for (method in c("M0", "M1", "M2", "M3")) {
    a <- br_advance(f$pred, f$tpe, H = 3, k = 4, nsim = 50,
                    method = method, seed = 312)
    expect_equal(a$candidates$p_advance, rep(1, 4))
    expect_equal(a$probability_sum, 4)
  }
})

test_that("zero-weight TPE states do not enter environmental draws", {
  f <- make_fixture()
  X <- rbind(f$tpe$basis[1, ], c(99, -500), f$tpe$basis[3, ])
  colnames(X) <- f$pred$basis_names
  tpe_zero <- br_tpe(X, c(.5, 0, .5))
  env_draws <- BreedReliabR:::.br_sample_env_mean(tpe_zero, H = 1, nsim = 1000)
  expect_true(all(env_draws[, 2] %in% c(-1, 1)))
})
