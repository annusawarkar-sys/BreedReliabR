#' Estimate genotype advancement probabilities
#'
#' @param prediction A `br_prediction` object.
#' @param tpe A `br_tpe` object.
#' @param H Number of future environments.
#' @param k Number of candidates to advance.
#' @param nsim Number of Monte Carlo draws for M1-M3.
#' @param method One of M0, M1, M2, M3.
#' @param seed Optional random seed.
#' @param tol Numerical tolerance.
#' @return An object of class `br_advancement`.
#' @export
br_advance <- function(prediction, tpe, H = 5L, k, nsim = 5000L,
                       method = c("M3", "M1", "M2", "M0"),
                       seed = NULL, tol = 1e-10) {
  .br_check_compatibility(prediction, tpe)
  tol <- .br_tolerance(tol)
  method <- match.arg(method)
  n <- length(prediction$candidates)
  p <- length(prediction$basis_names)
  H <- .br_scalar_integer(H, "H", min = 1L)
  k <- .br_scalar_integer(k, "k", min = 1L, max = n)
  if (method == "M0") {
    nsim <- 1L
  } else {
    nsim <- .br_scalar_integer(nsim, "nsim", min = 2L)
  }
  if (!is.null(seed)) base::set.seed(seed)

  mu_x <- as.numeric(crossprod(tpe$weights, tpe$basis))
  point_merit <- as.numeric(prediction$coef_mean %*% mu_x)
  merit_set_idx <- .br_topk(point_merit, k, prediction$candidates)

  if (method == "M0") {
    p_adv <- numeric(n)
    p_adv[merit_set_idx] <- 1
    mcse <- rep(0, n)
    sims_used <- 1L
  } else {
    mean_vec <- .br_vec_candidate_major(prediction$coef_mean)
    zero_pred <- max(abs(prediction$coef_vcov)) <= tol
    if (method %in% c("M1", "M3")) {
      if (zero_pred) {
        coef_draws <- matrix(rep(mean_vec, each = nsim), nrow = nsim)
      } else {
        coef_draws <- .br_rmvnorm(nsim, mean_vec, prediction$coef_vcov, tol = tol)
      }
    }

    if (method %in% c("M2", "M3")) {
      env_mean <- .br_sample_env_mean(tpe, H, nsim)
    }

    scores <- matrix(NA_real_, nrow = nsim, ncol = n)
    colnames(scores) <- prediction$candidates

    if (method == "M1") {
      for (i in seq_len(n)) {
        idx <- .br_candidate_block(i, p)
        scores[, i] <- as.numeric(coef_draws[, idx, drop = FALSE] %*% mu_x)
      }
    } else if (method == "M2") {
      for (i in seq_len(n)) {
        scores[, i] <- rowSums(sweep(env_mean, 2L, prediction$coef_mean[i, ], `*`))
      }
    } else if (method == "M3") {
      for (i in seq_len(n)) {
        idx <- .br_candidate_block(i, p)
        scores[, i] <- rowSums(coef_draws[, idx, drop = FALSE] * env_mean)
      }
    }

    counts <- integer(n)
    for (s in seq_len(nsim)) {
      sel <- .br_topk(scores[s, ], k, prediction$candidates)
      counts[sel] <- counts[sel] + 1L
    }
    p_adv <- counts / nsim
    mcse <- sqrt(p_adv * (1 - p_adv) / nsim)
    sims_used <- nsim
  }

  prob_set_idx <- .br_topk(p_adv, k, prediction$candidates)
  result <- data.frame(
    candidate = prediction$candidates,
    expected_merit = point_merit,
    p_advance = p_adv,
    mcse = mcse,
    in_expected_merit_set = seq_len(n) %in% merit_set_idx,
    in_probability_set = seq_len(n) %in% prob_set_idx,
    stringsAsFactors = FALSE
  )
  result <- result[order(-result$expected_merit, result$candidate), , drop = FALSE]
  rownames(result) <- NULL

  invariant <- sum(p_adv)
  structure(
    list(
      method = method,
      H = H,
      k = k,
      nsim = sims_used,
      candidates = result,
      expected_merit_set = prediction$candidates[merit_set_idx],
      probability_set = prediction$candidates[prob_set_idx],
      expected_merit_set_reliability = if (method == "M0") NA_real_ else mean(p_adv[merit_set_idx]),
      probability_set_reliability = if (method == "M0") NA_real_ else mean(p_adv[prob_set_idx]),
      probability_sum = invariant,
      invariant_error = invariant - k,
      seed = seed,
      conditionality = "Conditional on the supplied prediction distribution and specified TPE."
    ),
    class = "br_advancement"
  )
}

#' @export
print.br_advancement <- function(x, ...) {
  cat("BreedReliabR advancement analysis\n")
  cat("Method:", x$method, "\n")
  cat("Future environments H:", x$H, "\n")
  cat("Candidates advanced k:", x$k, "\n")
  cat("Monte Carlo draws:", x$nsim, "\n")
  if (is.na(x$expected_merit_set_reliability)) {
    cat("Expected-merit set reliability: not estimated by M0\n")
  } else {
    cat("Expected-merit set reliability:", format(x$expected_merit_set_reliability, digits = 4), "\n")
  }
  cat("Probability sum:", format(x$probability_sum, digits = 8), "(target", x$k, ")\n")
  cat(x$conditionality, "\n")
  invisible(x)
}
