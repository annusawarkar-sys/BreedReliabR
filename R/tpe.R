#' Define a target population of environments
#'
#' @param basis Numeric matrix with one row per TPE state and environmental basis
#'   columns matching the prediction object.
#' @param weights Non-negative state weights. They are normalised to sum to one.
#' @param state_id Optional state identifiers.
#' @param metadata Optional named list.
#' @return An object of class `br_tpe`.
#' @export
br_tpe <- function(basis, weights = NULL, state_id = NULL, metadata = list()) {
  basis <- as.matrix(basis)
  if (!.br_real_numeric(basis)) .br_stop("`basis` must be real numeric data.")
  if (nrow(basis) < 1L || ncol(basis) < 1L || any(!is.finite(basis))) {
    .br_stop("`basis` must be a finite numeric matrix with at least one row and one column.")
  }
  if (is.null(colnames(basis)) || anyNA(colnames(basis)) ||
      any(colnames(basis) == "") || anyDuplicated(colnames(basis))) {
    .br_stop("`basis` must have unique column names matching prediction basis terms.")
  }
  m <- nrow(basis)
  if (is.null(weights)) weights <- rep(1 / m, m)
  if (!.br_real_numeric(weights)) .br_stop("`weights` must be real numeric data.")
  weights <- as.numeric(weights)
  if (!.br_real_numeric(weights) || length(weights) != m || anyNA(weights) ||
      any(!is.finite(weights)) || any(weights < 0)) {
    .br_stop("`weights` must be finite, non-negative, and have one value per TPE state.")
  }
  max_weight <- max(weights)
  if (max_weight <= 0) .br_stop("At least one TPE weight must be positive.")
  # Scale before summing so valid finite weights cannot overflow their total.
  weights <- weights / max_weight
  weights <- weights / sum(weights)
  if (is.null(state_id)) state_id <- paste0("E", seq_len(m))
  state_id <- as.character(state_id)
  if (length(state_id) != m || anyNA(state_id) || any(state_id == "") || anyDuplicated(state_id)) {
    .br_stop("`state_id` must uniquely identify every TPE state.")
  }
  rownames(basis) <- state_id

  structure(
    list(basis = basis, weights = weights, state_id = state_id, metadata = metadata),
    class = "br_tpe"
  )
}

#' @export
print.br_tpe <- function(x, ...) {
  cat("BreedReliabR target population of environments\n")
  cat("States:", nrow(x$basis), "\n")
  cat("Basis terms:", ncol(x$basis), "\n")
  cat("Weight sum:", format(sum(x$weights), digits = 6), "\n")
  invisible(x)
}
