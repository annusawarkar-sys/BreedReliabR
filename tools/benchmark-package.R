args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args)) args[[1L]] else "performance_benchmark.csv"
if (!requireNamespace("BreedReliabR", quietly = TRUE)) {
  stop("Install BreedReliabR before running this benchmark.")
}

make_case <- function(n, p = 3L, rank = 15L) {
  set.seed(20260928 + n)
  coef_mean <- cbind(intercept = rnorm(n), PC1 = rnorm(n, sd = .25),
                     PC2 = rnorm(n, sd = .25))
  d <- n * p
  factor <- matrix(rnorm(d * rank), nrow = d, ncol = rank)
  P <- tcrossprod(factor) / rank + diag(.1, d)
  pred <- BreedReliabR::br_prediction(paste0("G", seq_len(n)), coef_mean, P)
  states <- seq(-1, 1, length.out = 21)
  X <- cbind(intercept = 1, PC1 = states,
             PC2 = sin(pi * states))
  tpe <- BreedReliabR::br_tpe(X)
  list(prediction = pred, tpe = tpe, covariance_bytes = as.numeric(object.size(P)))
}

measure <- function(label, n, fn, covariance_bytes, nsim) {
  invisible(gc(reset = TRUE))
  elapsed <- unname(system.time(value <- fn())["elapsed"])
  used <- gc()
  peak_mb <- sum(used[, "max used"] * 8) / 1024^2
  rm(value)
  data.frame(function_name = label, candidates = n, terms = 3L,
             coefficient_dimension = n * 3L, nsim = nsim,
             elapsed_seconds = elapsed, peak_R_heap_mb = peak_mb,
             dense_covariance_mb = covariance_bytes / 1024^2,
             stringsAsFactors = FALSE)
}

rows <- list()
counter <- 1L
nsim <- 200L
for (n in c(100L, 250L, 500L, 1000L)) {
  case <- make_case(n)
  p <- case$prediction
  t <- case$tpe
  k <- max(1L, as.integer(round(.1 * n)))
  Pbytes <- case$covariance_bytes
  specs <- list(
    br_omega = function() BreedReliabR::br_omega(p, t, H = c(1, 5)),
    M1 = function() BreedReliabR::br_advance(p, t, H = 5, k = k,
      nsim = nsim, method = "M1", seed = 701),
    M2 = function() BreedReliabR::br_advance(p, t, H = 5, k = k,
      nsim = nsim, method = "M2", seed = 701),
    M3 = function() BreedReliabR::br_advance(p, t, H = 5, k = k,
      nsim = nsim, method = "M3", seed = 701),
    br_compare = function() BreedReliabR::br_compare(p, t, H = 5, k = k,
      nsim = nsim, seed = 701),
    br_curve = function() BreedReliabR::br_curve(p, t, H = c(1, 5), k = k,
      nsim = nsim, seed = 701)
  )
  for (label in names(specs)) {
    rows[[counter]] <- measure(label, n, specs[[label]], Pbytes, nsim)
    counter <- counter + 1L
  }
  rm(case, p, t)
  invisible(gc())
}
result <- do.call(rbind, rows)
utils::write.csv(result, out_file, row.names = FALSE)
cat("Saved benchmark to", normalizePath(out_file, mustWork = FALSE), "\n")
