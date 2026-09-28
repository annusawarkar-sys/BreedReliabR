test_that("comparison exactly delegates all scenarios and preserves inputs", {
  f <- make_fixture()
  before <- serialize(f, NULL)
  x <- br_compare(f$pred, f$tpe, H = 3, k = 2, nsim = 200, seed = 12)
  expect_s3_class(x, "br_comparison")
  for (m in c("M0", "M1", "M2", "M3")) {
    expect_identical(x$analyses[[m]], br_advance(f$pred, f$tpe,
      H = 3, k = 2, nsim = 200, method = m, seed = 12))
  }
  expect_identical(serialize(f, NULL), before)
  expect_equal(x$summary$probability_sum, rep(2, 4))
  expect_true(is.na(x$summary$expected_merit_set_reliability[1]))
  z <- x$analyses$M3$candidates
  expect_equal(x$summary$expected_merit_set_reliability[4],
    mean(z$p_advance[z$in_expected_merit_set]))
  expect_error(br_compare(f$pred, f$tpe, k = 0), "k")
  expect_error(br_compare(f$pred, f$tpe, k = 2, nsim = 1), "nsim")
})

test_that("curve retains requested H order, core values and invariants", {
  f <- make_fixture()
  x <- br_curve(f$pred, f$tpe, H = c(5, 1, 5, 3), k = 2, nsim = 100, seed = 3)
  expect_identical(x$H, c(5L, 1L, 3L))
  expect_identical(x$omega, br_omega(f$pred, f$tpe, c(5, 1, 3)))
  expect_identical(x$comparisons[[2]], br_compare(f$pred, f$tpe,
    H = 1, k = 2, nsim = 100, seed = 3))
  expect_equal(x$summary$probability_sum, rep(2, 12))
  m1 <- x$summary$expected_merit_set_reliability[x$summary$method == "M1"]
  expect_equal(m1, rep(m1[1], 3))
  for (h in list(numeric(), NA, Inf, 0, 1.2, "1", 3e9)) {
    expect_error(br_curve(f$pred, f$tpe, H = h, k = 2), "H")
  }
  x1 <- br_curve(f$pred, f$tpe, H = 1, k = 4, nsim = 20, seed = 2)
  expect_equal(x1$summary$expected_merit_set_reliability[-1], rep(1, 3))
})

test_that("research wrappers preserve zero-uncertainty limits", {
  f <- make_fixture(zero_env = TRUE)
  z <- br_compare(f$pred, f$tpe, k = 2, nsim = 100, seed = 7)
  expect_equal(z$analyses$M1$candidates, z$analyses$M3$candidates)
  f <- make_fixture(zero_pred = TRUE)
  z <- br_compare(f$pred, f$tpe, k = 2, nsim = 100, seed = 7)
  expect_equal(z$analyses$M2$candidates, z$analyses$M3$candidates)
  f <- make_fixture(zero_pred = TRUE, zero_env = TRUE)
  z <- br_curve(f$pred, f$tpe, H = c(1, 3), k = 2, nsim = 20, seed = 7)
  expect_equal(z$omega$candidate$omega, rep(0, 8))
  expect_true(all(z$summary$expected_merit_set_reliability[z$summary$method != "M0"] == 1))
})

test_that("support diagnostics agree with hand calculations", {
  train <- cbind(intercept = 1, stress = c(0, 1, 2))
  tpe <- br_tpe(cbind(intercept = c(1, 1, 2, 1), stress = c(1, 4, 1, 9)),
    c(2, 1, 1, 0))
  z <- br_support(tpe, train)
  expect_equal(z$states$nearest_distance, c(0, 2, Inf, 7))
  expect_equal(z$states$outside_range, c(FALSE, TRUE, TRUE, TRUE))
  expect_equal(z$summary$weight_outside_range, .5)
  expect_equal(z$summary$weight_constant_mismatch, .25)
  expect_equal(z$training_nearest_distance, rep(1, 3))
  expect_equal(z$summary$weight_beyond_training_max_nn, .5)
  train2 <- train; train2[,2] <- 10 + train2[,2] * 7
  tpe2 <- tpe; tpe2$basis[,2] <- 10 + tpe2$basis[,2] * 7
  expect_equal(br_support(tpe2, train2)$states$nearest_distance, z$states$nearest_distance)
  expect_equal(br_support(tpe, train[3:1, ])$summary, z$summary)
})

test_that("support handles duplicates, constant spaces and rejects mismatches", {
  train <- cbind(intercept = c(1, 1))
  tpe <- br_tpe(cbind(intercept = c(1, 2)))
  z <- br_support(tpe, train)
  expect_equal(z$states$nearest_distance, c(0, Inf))
  expect_equal(z$training_nearest_distance, c(0, 0))
  expect_equal(br_support(br_tpe(cbind(intercept = 1 + 1e-12)), train)$states$nearest_distance, 0)
  expect_error(br_support(tpe, train[1, , drop = FALSE]), "at least two")
  expect_error(br_support(tpe, cbind(other = c(1, 1))), "match")
  expect_error(br_support(tpe, cbind(intercept = c(1, NA))), "finite")
  expect_error(br_support(tpe, train, tol = -1), "tol")
  expect_error(br_support(tpe, train, tol = NA_real_), "tol")
})

test_that("simulated data are internally coherent and explicitly labelled", {
  d <- maize_demo
  expect_true(d$provenance$simulated)
  expect_false(any(d$candidates$phenotyped))
  expect_length(intersect(d$candidates$candidate, d$training_phenotypes$genotype), 0)
  p <- do.call(br_prediction, d$prediction_inputs)
  t <- br_tpe(d$tpe_basis, d$tpe_states$weight, d$tpe_states$state_id)
  expect_identical(p$basis_names, colnames(d$training_basis))
  expect_equal(br_support(t, d$training_basis)$summary$weight_outside_range, .05)
  expect_true(min(eigen(p$coef_vcov, symmetric = TRUE)$values) > 0)
})

test_that("S3 displays return useful values, including one-H plots", {
  f <- make_fixture()
  a <- br_compare(f$pred, f$tpe, k = 2, nsim = 20, seed = 1)
  b <- br_curve(f$pred, f$tpe, H = 1, k = 2, nsim = 20, seed = 1)
  s <- br_support(f$tpe, f$tpe$basis)
  expect_identical(summary(a), a$summary)
  expect_identical(summary(b)$omega, b$omega$summary)
  expect_identical(summary(s), s$summary)
  expect_output(print(a), "M0-M3")
  expect_output(print(b), "versus H")
  expect_output(print(s), "Geometric support")
  expect_match(s$conditionality, "do not.*establish biological correctness")
  file <- tempfile(fileext = ".pdf")
  grDevices::pdf(file)
  on.exit({grDevices::dev.off(); unlink(file)}, add = TRUE)
  expect_identical(plot(a), a)
  expect_identical(plot(b), b)
  expect_identical(plot(b, type = "omega"), b)
  expect_identical(plot(b, set = "probability"), b)
  expect_identical(plot(s), s)
  b$omega$summary$median_omega <- Inf
  expect_warning(expect_error(plot(b, type = "omega"), "No finite"), "Infinite")
})
