br_support <- function(tpe, training_basis, tol = 1e-10) {
  .br_assert_tpe(tpe)
  X <- as.matrix(training_basis)
  if (!.br_real_numeric(X) || nrow(X) < 2L || any(!is.finite(X))) {
    .br_stop("`training_basis` must be finite numeric data with at least two rows.")
  }
  if (!identical(colnames(X), colnames(tpe$basis))) {
    .br_stop("Training and TPE columns must match exactly in name and order.")
  }
  tol <- .br_tolerance(tol)
  lo <- apply(X, 2L, min)
  hi <- apply(X, 2L, max)
  scales <- apply(X, 2L, stats::sd)
  constant <- hi == lo
  Y <- tpe$basis
  outside <- sweep(Y, 2L, lo - tol, `<`) | sweep(Y, 2L, hi + tol, `>`)
  constant_mismatch <- if (any(constant)) {
    rowSums(outside[, constant, drop = FALSE]) > 0
  } else rep(FALSE, nrow(Y))
  active <- !constant
  if (any(active)) {
    A <- sweep(X[, active, drop = FALSE], 2L, lo[active], `-`)
    A <- sweep(A, 2L, scales[active], `/`)
    B <- sweep(Y[, active, drop = FALSE], 2L, lo[active], `-`)
    B <- sweep(B, 2L, scales[active], `/`)
    nearest <- vapply(seq_len(nrow(B)), function(i) {
      min(sqrt(rowSums(sweep(A, 2L, B[i, ], `-`)^2)))
    }, numeric(1))
    loo <- vapply(seq_len(nrow(A)), function(i) {
      d <- sqrt(rowSums(sweep(A, 2L, A[i, ], `-`)^2))
      min(d[-i])
    }, numeric(1))
  } else {
    nearest <- rep(0, nrow(Y))
    loo <- rep(0, nrow(X))
  }
  # A departure in a constant training dimension has no finite standardized distance.
  nearest[constant_mismatch] <- Inf
  states <- data.frame(state_id = tpe$state_id, weight = tpe$weights,
    outside_range = rowSums(outside) > 0, n_outside = rowSums(outside),
    constant_mismatch = constant_mismatch, nearest_distance = nearest,
    beyond_training_max_nn = nearest > max(loo), stringsAsFactors = FALSE)
  mass <- sum(states$weight[states$outside_range])
  tab <- data.frame(weight_outside_range = mass,
    weight_constant_mismatch = sum(states$weight[constant_mismatch]),
    weight_beyond_training_max_nn = sum(states$weight[states$beyond_training_max_nn]),
    training_median_nn = stats::median(loo), training_max_nn = max(loo))
  structure(list(states = states, summary = tab,
    ranges = data.frame(term = colnames(X), min = lo, max = hi,
      sd = scales, constant = constant, row.names = NULL),
    outside_by_term = outside, training_nearest_distance = loo,
    tol = tol, conditionality = paste("Geometric support only; these diagnostics do not",
      "establish biological correctness of the specified TPE or prediction calibration.")),
    class = "br_support")
}

print.br_support <- function(x, ...) {
  cat("BreedReliabR environmental support diagnostics\n")
  print(x$summary, row.names = FALSE, ...)
  cat(x$conditionality, "\n")
  invisible(x)
}

summary.br_support <- function(object, ...) object$summary

plot.br_support <- function(x, ...) {
  d <- x$states$nearest_distance
  finite <- is.finite(d)
  if (!all(finite)) warning("Infinite distances are omitted; inspect constant_mismatch.", call. = FALSE)
  if (!any(finite)) .br_stop("No finite support distances to plot.")
  graphics::plot(which(finite), d[finite], pch = 19, xaxt = "n",
    col = ifelse(x$states$outside_range[finite], 2, 1),
    xlab = "TPE state", ylab = "Nearest training distance (SD units)", ...)
  graphics::axis(1, at = which(finite), labels = x$states$state_id[finite], las = 2)
  graphics::abline(h = x$summary$training_max_nn, lty = 2)
  invisible(x)
}
