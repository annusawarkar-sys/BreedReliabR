.br_stop <- function(..., call. = FALSE) stop(..., call. = call.)

.br_real_numeric <- function(x) is.numeric(x) && !is.complex(x)

.br_scalar_integer <- function(x, name, min = 1L, max = .Machine$integer.max) {
  if (!.br_real_numeric(x) || length(x) != 1L || is.na(x) ||
      !is.finite(x) || x != floor(x)) {
    .br_stop(sprintf("`%s` must be a single whole number.", name))
  }
  upper <- base::min(max, .Machine$integer.max)
  if (x < min || x > upper) {
    .br_stop(sprintf("`%s` must be between %s and %s.", name, min, upper))
  }
  as.integer(x)
}

.br_integer_vector <- function(x, name, min = 1L) {
  if (!.br_real_numeric(x) || !length(x) || anyNA(x) || any(!is.finite(x)) ||
      any(x != floor(x)) || any(x < min) || any(x > .Machine$integer.max)) {
    .br_stop(sprintf("`%s` must contain representable whole numbers greater than or equal to %s.", name, min))
  }
  as.integer(x)
}

.br_tolerance <- function(tol, name = "tol") {
  if (!.br_real_numeric(tol) || length(tol) != 1L || is.na(tol) ||
      !is.finite(tol) || tol < 0) {
    .br_stop(sprintf("`%s` must be a finite non-negative scalar.", name))
  }
  as.numeric(tol)
}

.br_assert_prediction <- function(x) {
  if (!inherits(x, "br_prediction")) .br_stop("`prediction` must be a br_prediction object.")
}

.br_assert_tpe <- function(x) {
  if (!inherits(x, "br_tpe")) .br_stop("`tpe` must be a br_tpe object.")
}

.br_vec_candidate_major <- function(mat) as.numeric(t(mat))

.br_candidate_block <- function(i, p) ((i - 1L) * p + 1L):(i * p)

.br_check_compatibility <- function(prediction, tpe) {
  .br_assert_prediction(prediction)
  .br_assert_tpe(tpe)
  if (!identical(prediction$basis_names, colnames(tpe$basis))) {
    .br_stop("Environmental basis columns in `tpe` must exactly match `prediction$basis_names` in name and order.")
  }
  invisible(TRUE)
}

.br_topk <- function(x, k, ids) {
  # Candidate ID is the deterministic tie-breaker.
  order(-x, ids)[seq_len(k)]
}

.br_rmvnorm <- function(n, mean, sigma, tol = 1e-10) {
  d <- length(mean)
  if (!all(dim(sigma) == c(d, d))) .br_stop("Internal covariance dimension mismatch.")
  if (max(abs(sigma)) <= tol) {
    return(matrix(rep(mean, each = n), nrow = n, byrow = FALSE))
  }
  ee <- eigen((sigma + t(sigma)) / 2, symmetric = TRUE)
  scale <- max(1, max(abs(ee$values)))
  if (min(ee$values) < -tol * scale) {
    .br_stop("Prediction covariance is not positive semidefinite within tolerance.")
  }
  vals <- pmax(ee$values, 0)
  A <- ee$vectors %*% diag(sqrt(vals), nrow = d)
  Z <- matrix(stats::rnorm(n * d), nrow = n, ncol = d)
  sweep(Z %*% t(A), 2L, mean, `+`)
}

.br_sample_env_mean <- function(tpe, H, nsim) {
  m <- nrow(tpe$basis)
  p <- ncol(tpe$basis)
  idx <- matrix(
    sample.int(m, size = nsim * H, replace = TRUE, prob = tpe$weights),
    nrow = nsim,
    ncol = H
  )
  out <- matrix(0, nrow = nsim, ncol = p)
  for (j in seq_len(p)) {
    vals <- tpe$basis[, j]
    out[, j] <- rowMeans(matrix(vals[idx], nrow = nsim, ncol = H))
  }
  colnames(out) <- colnames(tpe$basis)
  out
}
