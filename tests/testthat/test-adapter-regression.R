test_that("marker-space adapter preserves candidate-major means and full PEV", {
  # Compact synthetic regression fixture: M maps two marker effects to three
  # candidates; B %*% t(B) is the frozen joint marker-effect PEV.
  M <- rbind(c(1, 0), c(.5, sqrt(.75)), c(0, 1))
  n <- nrow(M)
  p <- 3L
  m <- ncol(M)
  A <- matrix(0, nrow = n * p, ncol = p * m)
  for (i in seq_len(n)) for (j in seq_len(p)) {
    A[(i - 1L) * p + j, (j - 1L) * m + seq_len(m)] <- M[i, ]
  }
  a_mean <- c(1, .5, .2, -.1, -.3, .4)
  B <- matrix(c(
    .12, .02, .00, .00,
    .04, .10, .01, .00,
    .03, .00, .08, .01,
    .02, .03, .11, .00,
    .00, .02, .04, .10,
    .01, .00, .02, .12
  ), nrow = 6, byrow = TRUE)
  C_a <- tcrossprod(B)
  coef_vec <- as.numeric(A %*% a_mean)
  coef_mean <- matrix(coef_vec, nrow = n, byrow = TRUE,
                      dimnames = list(NULL, c("intercept", "PC1", "PC2")))
  C_candidate <- A %*% C_a %*% t(A)
  dimnames(C_candidate) <- NULL

  pred <- br_prediction(paste0("C", seq_len(n)), coef_mean, C_candidate)
  expect_equal(as.numeric(t(pred$coef_mean)), coef_vec, tolerance = 1e-12)
  expect_equal(pred$coef_vcov, C_candidate, tolerance = 1e-12)
  expect_identical(pred$ordering, "candidate-major")
  expect_gt(abs(pred$coef_vcov[1, 5]), 0) # cross-candidate coefficient covariance
  expect_gt(abs(pred$coef_vcov[1, 2]), 0) # cross-coefficient covariance

  X <- rbind(c(1, -1, .5), c(1, 0, 0), c(1, 1, -.5))
  colnames(X) <- c("intercept", "PC1", "PC2")
  tpe <- br_tpe(X, c(.25, .5, .25))
  x_bar <- as.numeric(crossprod(tpe$weights, tpe$basis))
  W <- matrix(0, nrow = n, ncol = n * p)
  for (i in seq_len(n)) W[i, (i - 1L) * p + seq_len(p)] <- x_bar
  response_pev <- W %*% pred$coef_vcov %*% t(W)
  manual_diagonal <- vapply(seq_len(n), function(i) {
    ix <- (i - 1L) * p + seq_len(p)
    as.numeric(t(x_bar) %*% pred$coef_vcov[ix, ix, drop = FALSE] %*% x_bar)
  }, numeric(1))
  expect_equal(diag(response_pev), manual_diagonal, tolerance = 1e-12)
  expect_gt(abs(response_pev[1, 2]), 0)
})

test_that("frozen synthetic M0-M3 fixture agrees with reference probabilities", {
  f <- make_fixture()
  ref <- utils::read.csv(testthat::test_path("fixtures", "method-reference.csv"),
                         stringsAsFactors = FALSE)
  for (method in c("M0", "M1", "M2", "M3")) {
    # These are Monte Carlo estimates. Use enough draws that random-number
    # stream and eigensolver differences across OS/BLAS remain small compared
    # with the fixed regression tolerance.
    a <- br_advance(f$pred, f$tpe, H = 5, k = 2, nsim = 50000,
                    method = method, seed = 321)
    observed <- a$candidates$p_advance[match(ref$candidate[ref$method == method],
                                              a$candidates$candidate)]
    expect_equal(observed, ref$p_advance[ref$method == method], tolerance = .02,
                 info = paste("reference method", method))
  }
})

test_that("cross-candidate covariance changes ranking uncertainty", {
  mu <- matrix(c(.1, 0, -.1), ncol = 1,
               dimnames = list(NULL, "intercept"))
  common <- br_prediction(c("A", "B", "C"), mu, matrix(1, 3, 3))
  independent <- br_prediction(c("A", "B", "C"), mu, diag(3))
  X <- matrix(1, nrow = 1, dimnames = list("E1", "intercept"))
  tpe <- br_tpe(X)
  a <- br_advance(common, tpe, H = 1, k = 1, nsim = 2000,
                  method = "M1", seed = 902)
  b <- br_advance(independent, tpe, H = 1, k = 1, nsim = 2000,
                  method = "M1", seed = 902)
  p_a <- setNames(a$candidates$p_advance, a$candidates$candidate)
  p_b <- setNames(b$candidates$p_advance, b$candidates$candidate)
  expect_equal(p_a[["A"]], 1)
  expect_lt(p_b[["A"]], .7)
})
