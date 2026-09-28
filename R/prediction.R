#' Construct a genomic prediction object
#'
#' @param candidates Unique candidate identifiers.
#' @param coef_mean Numeric matrix with one row per candidate and one column per
#'   environmental basis coefficient. The first column may be an intercept.
#' @param coef_vcov Full prediction-error covariance matrix for all candidate
#'   coefficients, stacked candidate by candidate.
#' @param basis_names Optional basis names. Defaults to colnames(coef_mean).
#' @param source Optional model source label.
#' @param metadata Optional named list.
#' @param tol Numerical tolerance for symmetry/PSD checks.
#' @return An object of class `br_prediction`.
#' @export
br_prediction <- function(candidates, coef_mean, coef_vcov,
                          basis_names = colnames(coef_mean),
                          source = NULL, metadata = list(), tol = 1e-8) {
  tol <- .br_tolerance(tol)
  coef_mean <- as.matrix(coef_mean)
  coef_vcov <- as.matrix(coef_vcov)
  if (!.br_real_numeric(coef_mean)) .br_stop("`coef_mean` must be real numeric data.")
  if (!.br_real_numeric(coef_vcov)) .br_stop("`coef_vcov` must be real numeric data.")
  n <- nrow(coef_mean)
  p <- ncol(coef_mean)

  if (length(candidates) != n) .br_stop("Length of `candidates` must equal nrow(coef_mean).")
  candidates <- as.character(candidates)
  if (anyNA(candidates) || any(candidates == "") || anyDuplicated(candidates)) {
    .br_stop("`candidates` must be non-missing, non-empty, and unique.")
  }
  if (n < 1L || p < 1L) .br_stop("`coef_mean` must have at least one row and one column.")
  if (any(!is.finite(coef_mean))) .br_stop("`coef_mean` must contain only finite values.")
  if (!all(dim(coef_vcov) == c(n * p, n * p))) {
    .br_stop("`coef_vcov` must have dimension (n_candidates * n_terms)^2.")
  }
  if (any(!is.finite(coef_vcov))) .br_stop("`coef_vcov` must contain only finite values.")
  scale <- max(1, max(abs(coef_vcov)))
  if (max(abs(coef_vcov - t(coef_vcov))) > tol * scale) {
    .br_stop("`coef_vcov` must be symmetric within tolerance.")
  }
  coef_vcov <- (coef_vcov + t(coef_vcov)) / 2
  eig <- eigen(coef_vcov, symmetric = TRUE, only.values = TRUE)$values
  if (min(eig) < -tol * max(1, max(abs(eig)))) {
    .br_stop("`coef_vcov` must be positive semidefinite within tolerance.")
  }

  if (is.null(basis_names)) basis_names <- paste0("b", seq_len(p))
  basis_names <- as.character(basis_names)
  if (length(basis_names) != p || anyNA(basis_names) || any(basis_names == "") || anyDuplicated(basis_names)) {
    .br_stop("`basis_names` must uniquely name every column of `coef_mean`.")
  }
  colnames(coef_mean) <- basis_names

  structure(
    list(
      candidates = candidates,
      coef_mean = coef_mean,
      coef_vcov = coef_vcov,
      basis_names = basis_names,
      source = source,
      metadata = metadata,
      ordering = "candidate-major"
    ),
    class = "br_prediction"
  )
}

#' @export
print.br_prediction <- function(x, ...) {
  cat("BreedReliabR prediction object\n")
  cat("Candidates:", length(x$candidates), "\n")
  cat("Environmental basis terms:", ncol(x$coef_mean), "\n")
  if (!is.null(x$source)) cat("Source:", x$source, "\n")
  invisible(x)
}
