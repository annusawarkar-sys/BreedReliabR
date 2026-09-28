br_curve <- function(prediction, tpe, H = c(1L, 3L, 5L, 10L, 20L),
                     k, nsim = 5000L, seed = NULL, tol = 1e-10) {
  .br_check_compatibility(prediction, tpe)
  if (!.br_real_numeric(H) || !length(H) || anyNA(H) ||
      any(!is.finite(H)) || any(H < 1 | H > .Machine$integer.max) ||
      any(H != floor(H))) .br_stop("`H` must contain positive representable integers.")
  H <- unique(as.integer(H))
  fits <- lapply(H, function(h) br_compare(prediction, tpe, H = h,
    k = k, nsim = nsim, seed = seed, tol = tol))
  names(fits) <- as.character(H)
  tab <- do.call(rbind, lapply(fits, `[[`, "summary"))
  candidates <- do.call(rbind, lapply(fits, `[[`, "candidates"))
  rownames(tab) <- rownames(candidates) <- NULL
  structure(list(H = H, omega = br_omega(prediction, tpe, H),
    summary = tab, candidates = candidates, comparisons = fits,
    seed = seed, conditionality = fits[[1L]]$conditionality), class = "br_curve")
}

print.br_curve <- function(x, ...) {
  cat("BreedReliabR reliability versus H\n")
  print(x$summary, row.names = FALSE, ...)
  cat("Reliability = expected retained fraction; no monotonicity is imposed.\n")
  cat(x$conditionality, "\n")
  invisible(x)
}

summary.br_curve <- function(object, ...) {
  list(reliability = object$summary, omega = object$omega$summary)
}

plot.br_curve <- function(x, type = c("reliability", "omega"),
                          set = c("expected_merit", "probability"), ...) {
  type <- match.arg(type)
  set <- match.arg(set)
  if (type == "omega") {
    z <- x$omega$summary
    z <- z[order(z$H), , drop = FALSE]
    finite <- is.finite(z$median_omega)
    if (!all(finite)) warning("Infinite Omega values are omitted from the plot.", call. = FALSE)
    if (!any(finite)) .br_stop("No finite median Omega values to plot.")
    graphics::plot(z$H[finite], z$median_omega[finite], type = "b",
      xlab = "Future environments H", ylab = "Median candidate Omega", ...)
  } else {
    H <- sort(x$H)
    field <- paste0(set, "_set_reliability")
    y <- vapply(c("M1", "M2", "M3"), function(m) {
      z <- x$summary[x$summary$method == m, ]
      z[[field]][match(H, z$H)]
    }, numeric(length(H)))
    y <- matrix(y, nrow = length(H), ncol = 3L)
    graphics::matplot(H, y, type = "b", pch = 1:3, col = 1:3,
      lty = 1:3, ylim = c(0, 1), xlab = "Future environments H",
      ylab = paste(set, "set: expected retained fraction"), ...)
    graphics::legend("bottomright", c("M1", "M2", "M3"), col = 1:3,
      lty = 1:3, pch = 1:3, bty = "n")
  }
  invisible(x)
}
