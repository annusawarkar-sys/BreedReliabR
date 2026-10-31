make_valid_br_inputs <- function() {
  candidates <- c("G01", "G02", "G03")
  basis_names <- c("intercept", "slope")

  coef_mean <- matrix(
    c(
      5.1, -0.2,
      5.0, -0.1,
      5.3, -0.3
    ),
    nrow = 3,
    byrow = TRUE,
    dimnames = list(candidates, basis_names)
  )

  order_names <- unlist(
    lapply(
      candidates,
      function(g) paste(g, basis_names, sep = "__")
    ),
    use.names = FALSE
  )

  coef_vcov <- matrix(0.01, nrow = 6, ncol = 6)
  diag(coef_vcov) <- 0.20
  dimnames(coef_vcov) <- list(order_names, order_names)

  tpe_basis <- matrix(
    c(
      1, -1,
      1,  0,
      1,  1
    ),
    nrow = 3,
    byrow = TRUE,
    dimnames = list(paste0("TPE", 1:3), basis_names)
  )

  training_basis <- matrix(
    c(
      1, -0.8,
      1, -0.2,
      1,  0.4,
      1,  0.9
    ),
    nrow = 4,
    byrow = TRUE,
    dimnames = list(paste0("E", 1:4), basis_names)
  )

  list(
    candidates = candidates,
    basis_names = basis_names,
    coef_mean = coef_mean,
    coef_vcov = coef_vcov,
    tpe_basis = tpe_basis,
    tpe_weights = c(0.2, 0.3, 0.5),
    training_basis = training_basis
  )
}

test_that("valid complete inputs pass", {
  z <- make_valid_br_inputs()
  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names,
    tpe_basis = z$tpe_basis,
    tpe_weights = z$tpe_weights,
    training_basis = z$training_basis,
    k = 2,
    H = 5
  )

  expect_s3_class(result, "br_input_check")
  expect_identical(result$status, "PASS")
  expect_false(any(result$checks$status == "ERROR"))
})

test_that("wrong covariance dimension is reported", {
  z <- make_valid_br_inputs()
  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = diag(3)
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "Covariance dimensions" &
      result$checks$status == "ERROR"
  ))
})

test_that("duplicate candidate identifiers fail", {
  z <- make_valid_br_inputs()
  result <- br_check_inputs(
    candidates = c("G01", "G01", "G03"),
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "Candidate uniqueness" &
      result$checks$status == "ERROR"
  ))
})

test_that("permuted canonical covariance labels fail", {
  z <- make_valid_br_inputs()
  permutation <- c(1, 3, 2, 4, 5, 6)
  bad_vcov <- z$coef_vcov[permutation, permutation]

  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = bad_vcov,
    basis_names = z$basis_names
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "Candidate-major labels" &
      result$checks$status == "ERROR"
  ))
})

test_that("unnamed covariance passes with warning when otherwise valid", {
  z <- make_valid_br_inputs()
  unnamed <- unname(z$coef_vcov)

  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = unnamed,
    basis_names = z$basis_names
  )

  expect_identical(result$status, "PASS WITH WARNINGS")
  expect_true(any(
    result$checks$item == "Candidate-major labels" &
      result$checks$status == "WARNING"
  ))
})

test_that("non-symmetric covariance fails", {
  z <- make_valid_br_inputs()
  bad <- z$coef_vcov
  bad[1, 2] <- bad[1, 2] + 0.1

  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = bad,
    basis_names = z$basis_names
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "Covariance symmetry" &
      result$checks$status == "ERROR"
  ))
})

test_that("non-PSD covariance fails", {
  z <- make_valid_br_inputs()
  bad <- z$coef_vcov
  bad[1, 1] <- -1

  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = bad,
    basis_names = z$basis_names
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "Covariance PSD" &
      result$checks$status == "ERROR"
  ))
})

test_that("near-boundary covariance produces downstream numerical warning", {
  candidates <- "G01"
  basis_names <- c("intercept", "slope")
  coef_mean <- matrix(
    c(5, 0.2),
    nrow = 1,
    dimnames = list(candidates, basis_names)
  )

  near_boundary <- matrix(
    c(
      1, 1,
      1, 1 - 1e-9
    ),
    nrow = 2,
    byrow = TRUE
  )
  nm <- c("G01__intercept", "G01__slope")
  dimnames(near_boundary) <- list(nm, nm)

  result <- br_check_inputs(
    candidates = candidates,
    coef_mean = coef_mean,
    coef_vcov = near_boundary,
    basis_names = basis_names
  )

  expect_false(any(
    result$checks$item == "Covariance PSD" &
      result$checks$status == "ERROR"
  ))
  expect_true(any(
    result$checks$item == "Downstream numerical margin" &
      result$checks$status == "WARNING"
  ))
})

test_that("TPE basis mismatch fails", {
  z <- make_valid_br_inputs()
  bad_tpe <- z$tpe_basis
  colnames(bad_tpe) <- c("intercept", "temperature")

  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names,
    tpe_basis = bad_tpe,
    tpe_weights = z$tpe_weights
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "TPE basis labels" &
      result$checks$status == "ERROR"
  ))
})

test_that("positive unnormalised TPE weights remain valid", {
  z <- make_valid_br_inputs()
  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names,
    tpe_basis = z$tpe_basis,
    tpe_weights = c(2, 3, 5)
  )

  weight_check <- subset(result$checks, item == "TPE weights")
  expect_identical(weight_check$status, "PASS")
})

test_that("invalid k and H are reported together", {
  z <- make_valid_br_inputs()
  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names,
    k = 4,
    H = c(1, 0, 5)
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "Advancement size k" &
      result$checks$status == "ERROR"
  ))
  expect_true(any(
    result$checks$item == "Future representation H" &
      result$checks$status == "ERROR"
  ))
})

test_that("TPE weights without a TPE basis fail cleanly", {
  z <- make_valid_br_inputs()
  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names,
    tpe_weights = z$tpe_weights
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "TPE weights" &
      result$checks$status == "ERROR"
  ))
})

test_that("malformed TPE input is diagnosed without internal error", {
  z <- make_valid_br_inputs()
  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names,
    tpe_basis = c(1, 2),
    tpe_weights = c(0.5, 0.5)
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(result$checks$item == "TPE basis"))
})

test_that("br_check_inputs does not alter supplied objects", {
  z <- make_valid_br_inputs()
  original_mean <- z$coef_mean
  original_vcov <- z$coef_vcov
  original_tpe <- z$tpe_basis

  invisible(br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = z$coef_vcov,
    basis_names = z$basis_names,
    tpe_basis = z$tpe_basis,
    tpe_weights = z$tpe_weights
  ))

  expect_identical(z$coef_mean, original_mean)
  expect_identical(z$coef_vcov, original_vcov)
  expect_identical(z$tpe_basis, original_tpe)
})

test_that("duplicate covariance dimension labels fail", {
  z <- make_valid_br_inputs()
  bad <- z$coef_vcov
  rn <- rownames(bad)
  rn[2] <- rn[1]
  rownames(bad) <- rn
  colnames(bad) <- rn

  result <- br_check_inputs(
    candidates = z$candidates,
    coef_mean = z$coef_mean,
    coef_vcov = bad,
    basis_names = z$basis_names
  )

  expect_identical(result$status, "FAIL")
  expect_true(any(
    result$checks$item == "Candidate-major labels" &
      result$checks$status == "ERROR"
  ))
})
