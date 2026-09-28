#' Quantify prediction versus finite-TPE uncertainty
#'
#' @param prediction A `br_prediction` object.
#' @param tpe A `br_tpe` object.
#' @param H Positive integer vector giving future network sizes.
#' @return An object of class `br_omega`.
#' @export
br_omega <- function(prediction, tpe, H = c(1L, 3L, 5L, 10L, 20L)) {
  .br_check_compatibility(prediction, tpe)
  H <- unique(.br_integer_vector(H, "H", min = 1L))

  X <- tpe$basis
  w <- tpe$weights
  mu_x <- as.numeric(crossprod(w, X))
  centered <- sweep(X, 2L, mu_x, `-`)
  Sigma_x <- crossprod(centered * sqrt(w), centered * sqrt(w))

  n <- length(prediction$candidates)
  p <- length(prediction$basis_names)
  out <- vector("list", n * length(H))
  ctr <- 1L

  for (i in seq_len(n)) {
    idx <- .br_candidate_block(i, p)
    Pi <- prediction$coef_vcov[idx, idx, drop = FALSE]
    mui <- as.numeric(prediction$coef_mean[i, ])
    pred_var <- as.numeric(t(mu_x) %*% Pi %*% mu_x)
    second_moment <- Pi + tcrossprod(mui)
    env_one <- sum(Sigma_x * t(second_moment))
    env_one <- max(env_one, 0)

    for (h in H) {
      env_var <- env_one / h
      omega <- if (pred_var <= .Machine$double.eps) {
        if (env_var <= .Machine$double.eps) 0 else Inf
      } else {
        env_var / pred_var
      }
      out[[ctr]] <- data.frame(
        candidate = prediction$candidates[i],
        H = h,
        expected_merit = sum(mu_x * mui),
        pred_var = pred_var,
        env_var = env_var,
        omega = omega,
        stringsAsFactors = FALSE
      )
      ctr <- ctr + 1L
    }
  }
  tab <- do.call(rbind, out)
  summary <- do.call(rbind, lapply(H, function(h) {
    z <- tab[tab$H == h, , drop = FALSE]
    data.frame(
      H = h,
      median_omega = stats::median(z$omega, na.rm = TRUE),
      median_pred_var = stats::median(z$pred_var),
      median_env_var = stats::median(z$env_var),
      stringsAsFactors = FALSE
    )
  }))

  structure(list(candidate = tab, summary = summary), class = "br_omega")
}

#' @export
print.br_omega <- function(x, ...) {
  cat("BreedReliabR uncertainty diagnostic\n")
  print(x$summary, row.names = FALSE)
  invisible(x)
}
