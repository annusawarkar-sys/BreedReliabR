# Research-facing wrappers; the H2 computational core is unchanged.
br_compare <- function(prediction, tpe, H = 5L, k, nsim = 5000L,
                       seed = NULL, tol = 1e-10) {
  .br_check_compatibility(prediction, tpe)
  methods <- c("M0", "M1", "M2", "M3")
  fits <- lapply(methods, function(method) {
    br_advance(prediction, tpe, H = H, k = k, nsim = nsim,
               method = method, seed = seed, tol = tol)
  })
  names(fits) <- methods
  candidates <- do.call(rbind, lapply(fits, function(z) {
    data.frame(method = z$method, H = z$H, z$candidates,
               row.names = NULL, stringsAsFactors = FALSE)
  }))
  tab <- do.call(rbind, lapply(fits, function(z) {
    data.frame(method = z$method, H = z$H, k = z$k, nsim = z$nsim,
      expected_merit_set_reliability = z$expected_merit_set_reliability,
      probability_set_reliability = z$probability_set_reliability,
      probability_sum = z$probability_sum, invariant_error = z$invariant_error,
      stringsAsFactors = FALSE)
  }))
  rownames(tab) <- rownames(candidates) <- NULL
  structure(list(summary = tab, candidates = candidates, analyses = fits,
    seed = seed, conditionality = fits$M3$conditionality), class = "br_comparison")
}

print.br_comparison <- function(x, ...) {
  cat("BreedReliabR M0-M3 comparison\n")
  print(x$summary, row.names = FALSE, ...)
  cat("Reliability = expected retained fraction; M0 does not estimate reliability.\n")
  cat(x$conditionality, "\n")
  invisible(x)
}

summary.br_comparison <- function(object, ...) object$summary

plot.br_comparison <- function(x, ...) {
  ids <- x$analyses$M0$candidates$candidate
  y <- vapply(x$analyses, function(z) {
    z$candidates$p_advance[match(ids, z$candidates$candidate)]
  }, numeric(length(ids)))
  y <- matrix(y, nrow = length(ids), ncol = 4L)
  graphics::matplot(seq_along(ids), y, type = "b", pch = 1:4,
    lty = 1:4, col = 1:4, ylim = c(0, 1), xaxt = "n",
    xlab = "Candidate (expected-merit order)", ylab = "Advancement probability", ...)
  graphics::axis(1, at = seq_along(ids), labels = ids, las = 2)
  graphics::legend("topright", legend = names(x$analyses), col = 1:4,
    lty = 1:4, pch = 1:4, bty = "n")
  invisible(x)
}
