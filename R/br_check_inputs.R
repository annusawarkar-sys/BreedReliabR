#' Check BreedReliabR input compatibility
#'
#' Performs a non-destructive structural audit of candidate coefficient
#' predictions, their full joint covariance, and optional target-environment
#' and decision inputs before BreedReliabR objects are constructed.
#'
#' The check is structural. It does not repair inputs or validate the upstream
#' prediction model, the adequacy of its covariance, the biological definition
#' of the target population of environments, or empirical calibration.
#'
#' @param candidates Candidate identifiers.
#' @param coef_mean Numeric n x p matrix of candidate coefficient means.
#' @param coef_vcov Numeric np x np full joint coefficient covariance.
#' @param basis_names Character vector of environmental-basis names.
#' @param tpe_basis Optional numeric matrix of target-environment basis values.
#' @param tpe_weights Optional non-negative target-state weights.
#' @param training_basis Optional numeric training-environment basis matrix.
#' @param k Optional fixed number of candidates to advance.
#' @param H Optional positive integer value or vector of values describing
#'   future TPE representation.
#' @param tol Numerical tolerance used for structural covariance checks.
#' @return An object of class `br_input_check`.
#' @export
br_check_inputs <- function(candidates, coef_mean, coef_vcov,
                            basis_names = colnames(coef_mean),
                            tpe_basis = NULL, tpe_weights = NULL,
                            training_basis = NULL, k = NULL, H = NULL,
                            tol = 1e-8) {
  tol <- .br_tolerance(tol)

  checks <- data.frame(
    item = character(),
    status = character(),
    message = character(),
    stringsAsFactors = FALSE
  )

  add_check <- function(item, status, message) {
    checks <<- rbind(
      checks,
      data.frame(
        item = item,
        status = status,
        message = message,
        stringsAsFactors = FALSE
      )
    )
  }

  whole_number <- function(x) {
    .br_real_numeric(x) && length(x) > 0L && !anyNA(x) &&
      all(is.finite(x)) && all(x == floor(x)) &&
      all(x <= .Machine$integer.max)
  }

  # Candidate identifiers ---------------------------------------------------
  candidate_ok <- !is.null(candidates) && is.atomic(candidates) &&
    length(candidates) > 0L

  if (!candidate_ok) {
    add_check(
      "Candidate identifiers", "ERROR",
      "Candidate identifiers must be a non-empty atomic vector."
    )
    candidate_chr <- character()
    n <- NA_integer_
  } else {
    candidate_chr <- as.character(candidates)
    n <- length(candidate_chr)

    if (anyNA(candidate_chr) || any(!nzchar(trimws(candidate_chr)))) {
      add_check(
        "Candidate identifiers", "ERROR",
        "Candidate identifiers contain missing or empty values."
      )
    } else {
      add_check(
        "Candidate identifiers", "PASS",
        paste(n, "candidate identifiers supplied.")
      )
    }

    if (anyDuplicated(candidate_chr)) {
      add_check(
        "Candidate uniqueness", "ERROR",
        "Candidate identifiers must be unique."
      )
    } else {
      add_check(
        "Candidate uniqueness", "PASS",
        "Candidate identifiers are unique."
      )
    }
  }

  # Coefficient mean matrix -------------------------------------------------
  coef_mean_ok <- is.matrix(coef_mean) && .br_real_numeric(coef_mean)

  if (!coef_mean_ok) {
    add_check(
      "Coefficient matrix", "ERROR",
      "`coef_mean` must be a real numeric matrix."
    )
    p <- NA_integer_
  } else {
    p <- ncol(coef_mean)

    if (nrow(coef_mean) < 1L || p < 1L) {
      add_check(
        "Coefficient matrix", "ERROR",
        "`coef_mean` must have at least one row and one column."
      )
    } else {
      add_check(
        "Coefficient matrix", "PASS",
        paste(
          "Supplied coefficient matrix is",
          nrow(coef_mean), "x", ncol(coef_mean), "."
        )
      )
    }

    if (!is.na(n) && nrow(coef_mean) != n) {
      add_check(
        "Coefficient rows", "ERROR",
        paste(
          "Expected", n, "coefficient rows but received",
          nrow(coef_mean), "."
        )
      )
    } else if (!is.na(n)) {
      add_check(
        "Coefficient rows", "PASS",
        "Coefficient rows match the candidate count."
      )
    }

    if (!all(is.finite(coef_mean))) {
      add_check(
        "Coefficient values", "ERROR",
        "`coef_mean` contains missing or non-finite values."
      )
    } else {
      add_check(
        "Coefficient values", "PASS",
        "All coefficient values are finite."
      )
    }

    if (!is.na(n)) {
      rn <- rownames(coef_mean)
      if (is.null(rn)) {
        add_check(
          "Coefficient row labels", "WARNING",
          paste(
            "`coef_mean` has no row names;",
            "candidate order cannot be cross-checked."
          )
        )
      } else if (identical(rn, candidate_chr)) {
        add_check(
          "Coefficient row labels", "PASS",
          "Coefficient rows match candidate order."
        )
      } else {
        add_check(
          "Coefficient row labels", "ERROR",
          paste(
            "`coef_mean` row names do not match",
            "the supplied candidate order."
          )
        )
      }
    }
  }

  # Basis names -------------------------------------------------------------
  basis_ok <- FALSE
  basis_chr <- character()

  if (is.null(basis_names) || length(basis_names) == 0L) {
    add_check(
      "Basis names", "ERROR",
      paste(
        "Environmental-basis names are required by the preflight",
        "checker so cross-object order can be verified."
      )
    )
  } else {
    basis_chr <- as.character(basis_names)
    basis_ok <- !anyNA(basis_chr) &&
      all(nzchar(trimws(basis_chr))) &&
      !anyDuplicated(basis_chr) &&
      (is.na(p) || length(basis_chr) == p)

    if (!basis_ok) {
      add_check(
        "Basis names", "ERROR",
        paste(
          "Basis names must be non-empty, unique,",
          "and match the number of coefficient columns."
        )
      )
    } else {
      add_check(
        "Basis names", "PASS",
        paste(length(basis_chr), "unique basis coefficients supplied.")
      )

      if (coef_mean_ok) {
        cm_names <- colnames(coef_mean)
        if (is.null(cm_names)) {
          add_check(
            "Coefficient column labels", "WARNING",
            paste(
              "`coef_mean` has no column names;",
              "basis order cannot be independently verified."
            )
          )
        } else if (!identical(cm_names, basis_chr)) {
          add_check(
            "Coefficient column labels", "ERROR",
            paste(
              "`coef_mean` column names do not match",
              "`basis_names` in the same order."
            )
          )
        } else {
          add_check(
            "Coefficient column labels", "PASS",
            "Coefficient columns match `basis_names`."
          )
        }
      }
    }
  }

  # Full joint covariance ---------------------------------------------------
  vcov_basic_ok <- is.matrix(coef_vcov) && .br_real_numeric(coef_vcov) &&
    nrow(coef_vcov) == ncol(coef_vcov)

  if (!vcov_basic_ok) {
    add_check(
      "Joint covariance", "ERROR",
      "`coef_vcov` must be a square real numeric matrix."
    )
  } else {
    expected_dim <- if (!is.na(n) && !is.na(p)) n * p else NA_real_

    if (!is.na(expected_dim) &&
        !all(dim(coef_vcov) == c(expected_dim, expected_dim))) {
      add_check(
        "Covariance dimensions", "ERROR",
        paste(
          n, "candidates x", p, "coefficients imply", expected_dim,
          "joint quantities; expected",
          paste0(expected_dim, " x ", expected_dim), "but received",
          paste(dim(coef_vcov), collapse = " x "), "."
        )
      )
    } else {
      add_check(
        "Covariance dimensions", "PASS",
        paste(
          "Joint covariance dimension is",
          paste(dim(coef_vcov), collapse = " x "), "."
        )
      )
    }

    if (!all(is.finite(coef_vcov))) {
      add_check(
        "Covariance values", "ERROR",
        "`coef_vcov` contains missing or non-finite values."
      )
    } else {
      add_check(
        "Covariance values", "PASS",
        "All covariance entries are finite."
      )

      covariance_scale <- max(1, max(abs(coef_vcov)))
      asymmetry <- max(abs(coef_vcov - t(coef_vcov)))

      if (asymmetry > tol * covariance_scale) {
        add_check(
          "Covariance symmetry", "ERROR",
          paste(
            "Covariance is not symmetric within tolerance;",
            "maximum scaled asymmetry exceeds", format(tol), "."
          )
        )
      } else {
        add_check(
          "Covariance symmetry", "PASS",
          "Covariance is symmetric within tolerance."
        )

        eigen_values <- eigen(
          (coef_vcov + t(coef_vcov)) / 2,
          symmetric = TRUE,
          only.values = TRUE
        )$values
        eigen_scale <- max(1, max(abs(eigen_values)))
        minimum_eigenvalue <- min(eigen_values)

        if (minimum_eigenvalue < -tol * eigen_scale) {
          add_check(
            "Covariance PSD", "ERROR",
            paste(
              "Covariance is not positive semidefinite",
              "within the constructor-compatible tolerance."
            )
          )
        } else {
          add_check(
            "Covariance PSD", "PASS",
            "Covariance is positive semidefinite within tolerance."
          )

          analysis_tol <- 1e-10
          if (minimum_eigenvalue < -analysis_tol * eigen_scale) {
            add_check(
              "Downstream numerical margin", "WARNING",
              paste(
                "The covariance passes the preflight/constructor tolerance",
                "but violates the tighter default tolerance used by",
                "stochastic coefficient sampling; M1/M3 advancement may stop",
                "unless the upstream covariance is resolved."
              )
            )
          } else {
            add_check(
              "Downstream numerical margin", "PASS",
              "Covariance is also within the tighter stochastic-sampling margin."
            )
          }
        }
      }
    }

    rn <- rownames(coef_vcov)
    cn <- colnames(coef_vcov)

    if (is.null(rn) && is.null(cn)) {
      add_check(
        "Candidate-major labels", "WARNING",
        paste(
          "Covariance has no dimension names;",
          "candidate-major ordering cannot be verified."
        )
      )
    } else if (is.null(rn) || is.null(cn)) {
      add_check(
        "Candidate-major labels", "WARNING",
        paste(
          "Only one covariance dimension is labelled;",
          "candidate-major ordering cannot be verified completely."
        )
      )
    } else if (anyNA(rn) || anyNA(cn) ||
               any(!nzchar(trimws(rn))) || any(!nzchar(trimws(cn))) ||
               anyDuplicated(rn) || anyDuplicated(cn)) {
      add_check(
        "Candidate-major labels", "ERROR",
        "Covariance dimension labels must be non-missing, non-empty, and unique."
      )
    } else if (!identical(rn, cn)) {
      add_check(
        "Candidate-major labels", "ERROR",
        "Covariance row and column labels do not match."
      )
    } else if (!is.na(n) && !is.na(p) && basis_ok) {
      expected_order <- unlist(
        lapply(
          candidate_chr,
          function(g) paste(g, basis_chr, sep = "__")
        ),
        use.names = FALSE
      )

      if (identical(rn, expected_order)) {
        add_check(
          "Candidate-major labels", "PASS",
          "Canonical candidate-major labels are consistent."
        )
      } else if (length(rn) == length(expected_order) &&
                 setequal(rn, expected_order)) {
        add_check(
          "Candidate-major labels", "ERROR",
          paste(
            "Canonical coefficient labels are present",
            "but occur in the wrong order."
          )
        )
      } else {
        add_check(
          "Candidate-major labels", "WARNING",
          paste(
            "Covariance labels do not use the canonical",
            "candidate__basis convention; ordering cannot be",
            "verified automatically."
          )
        )
      }
    }
  }

  # TPE basis and weights ---------------------------------------------------
  if (!is.null(tpe_basis)) {
    tpe_ok <- is.matrix(tpe_basis) && .br_real_numeric(tpe_basis)

    if (!tpe_ok) {
      add_check(
        "TPE basis", "ERROR",
        "`tpe_basis` must be a real numeric matrix."
      )
    } else {
      if (nrow(tpe_basis) < 1L || ncol(tpe_basis) < 1L) {
        add_check(
          "TPE dimensions", "ERROR",
          "`tpe_basis` must have at least one row and one column."
        )
      } else if (!is.na(p) && ncol(tpe_basis) != p) {
        add_check(
          "TPE dimensions", "ERROR",
          paste(
            "TPE has", ncol(tpe_basis), "basis columns but", p,
            "are required."
          )
        )
      } else {
        add_check(
          "TPE dimensions", "PASS",
          paste("TPE contains", nrow(tpe_basis), "target states.")
        )
      }

      if (!all(is.finite(tpe_basis))) {
        add_check(
          "TPE values", "ERROR",
          "`tpe_basis` contains missing or non-finite values."
        )
      } else {
        add_check(
          "TPE values", "PASS",
          "All TPE basis values are finite."
        )
      }

      if (basis_ok) {
        if (is.null(colnames(tpe_basis))) {
          add_check(
            "TPE basis labels", "ERROR",
            paste(
              "TPE basis columns must be named so compatibility",
              "with the prediction basis can be verified."
            )
          )
        } else if (!identical(colnames(tpe_basis), basis_chr)) {
          add_check(
            "TPE basis labels", "ERROR",
            "TPE basis names or order do not match the prediction basis."
          )
        } else {
          add_check(
            "TPE basis labels", "PASS",
            "TPE basis matches the prediction basis."
          )
        }
      }
    }

    if (is.null(tpe_weights)) {
      add_check(
        "TPE weights", "PASS",
        paste(
          "No explicit weights supplied;",
          "the `br_tpe()` default weighting behaviour will apply."
        )
      )
    } else if (!tpe_ok) {
      add_check(
        "TPE weights", "ERROR",
        "TPE weights cannot be checked until `tpe_basis` is a valid matrix."
      )
    } else if (!.br_real_numeric(tpe_weights) ||
               length(tpe_weights) != nrow(tpe_basis) ||
               anyNA(tpe_weights) || any(!is.finite(tpe_weights))) {
      add_check(
        "TPE weights", "ERROR",
        paste(
          "TPE weights must be finite real numeric values",
          "with one value per target state."
        )
      )
    } else if (any(tpe_weights < 0)) {
      add_check(
        "TPE weights", "ERROR",
        "TPE weights cannot be negative."
      )
    } else {
      max_weight <- max(tpe_weights)
      if (max_weight <= 0) {
        add_check(
          "TPE weights", "ERROR",
          "At least one TPE weight must be positive."
        )
      } else {
        scaled_total <- sum(tpe_weights / max_weight)
        raw_total <- sum(tpe_weights)
        if (is.finite(raw_total) && abs(raw_total - 1) <= tol) {
          add_check(
            "TPE weights", "PASS",
            "TPE weights are valid and sum to one."
          )
        } else {
          add_check(
            "TPE weights", "PASS",
            paste(
              "TPE weights are finite, non-negative, and have positive",
              "total mass; `br_tpe()` will normalise them.",
              "Scaled total:", signif(scaled_total, 6), "."
            )
          )
        }
      }
    }
  } else if (!is.null(tpe_weights)) {
    add_check(
      "TPE weights", "ERROR",
      "`tpe_weights` were supplied without `tpe_basis`."
    )
  }

  # Training basis ----------------------------------------------------------
  if (!is.null(training_basis)) {
    training_ok <- is.matrix(training_basis) &&
      .br_real_numeric(training_basis)

    if (!training_ok) {
      add_check(
        "Training basis", "ERROR",
        "`training_basis` must be a real numeric matrix."
      )
    } else {
      if (nrow(training_basis) < 1L || ncol(training_basis) < 1L) {
        add_check(
          "Training basis dimensions", "ERROR",
          "`training_basis` must have at least one row and one column."
        )
      } else if (!is.na(p) && ncol(training_basis) != p) {
        add_check(
          "Training basis dimensions", "ERROR",
          paste(
            "`training_basis` has", ncol(training_basis),
            "columns but", p, "are required."
          )
        )
      } else {
        add_check(
          "Training basis dimensions", "PASS",
          paste("Training basis contains", nrow(training_basis), "states.")
        )
      }

      if (!all(is.finite(training_basis))) {
        add_check(
          "Training basis values", "ERROR",
          "`training_basis` contains missing or non-finite values."
        )
      } else {
        add_check(
          "Training basis values", "PASS",
          "All training-basis values are finite."
        )
      }

      if (basis_ok) {
        if (is.null(colnames(training_basis)) ||
            !identical(colnames(training_basis), basis_chr)) {
          add_check(
            "Training basis labels", "ERROR",
            paste(
              "Training-basis columns must match `basis_names`",
              "in the same order."
            )
          )
        } else {
          add_check(
            "Training basis labels", "PASS",
            "Training basis matches the prediction basis."
          )
        }
      }
    }
  }

  # Decision parameters -----------------------------------------------------
  if (!is.null(k)) {
    if (!whole_number(k) || length(k) != 1L || is.na(n) ||
        k < 1 || k > n) {
      add_check(
        "Advancement size k", "ERROR",
        paste(
          "`k` must be one representable whole number between 1",
          "and the number of candidates."
        )
      )
    } else {
      add_check(
        "Advancement size k", "PASS",
        paste("k =", as.integer(k), "is valid.")
      )
    }
  }

  if (!is.null(H)) {
    if (!whole_number(H) || any(H < 1)) {
      add_check(
        "Future representation H", "ERROR",
        "`H` must contain positive representable whole-number values."
      )
    } else {
      add_check(
        "Future representation H", "PASS",
        paste(
          "Valid H value(s):",
          paste(as.integer(H), collapse = ", ")
        )
      )
    }
  }

  # Overall status ----------------------------------------------------------
  if (any(checks$status == "ERROR")) {
    overall_status <- "FAIL"
  } else if (any(checks$status == "WARNING")) {
    overall_status <- "PASS WITH WARNINGS"
  } else {
    overall_status <- "PASS"
  }

  dimensions <- list(
    n_candidates = if (!is.na(n)) n else NULL,
    n_basis = if (!is.na(p)) p else NULL,
    coef_mean = if (is.matrix(coef_mean)) dim(coef_mean) else NULL,
    expected_vcov = if (!is.na(n) && !is.na(p)) c(n * p, n * p) else NULL,
    supplied_vcov = if (is.matrix(coef_vcov)) dim(coef_vcov) else NULL
  )

  structure(
    list(
      status = overall_status,
      dimensions = dimensions,
      checks = checks,
      conditionality = paste(
        "Structural compatibility does not validate the upstream prediction",
        "model, adequacy of its covariance, biological definition of the TPE,",
        "or empirical probability calibration."
      )
    ),
    class = "br_input_check"
  )
}

#' Print a BreedReliabR input audit
#'
#' @param x A `br_input_check` object.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.br_input_check <- function(x, ...) {
  cat("BreedReliabR input audit\n")
  cat("========================\n\n")

  d <- x$dimensions
  if (!is.null(d$n_candidates)) {
    cat(sprintf("%-30s %s\n", "Candidates", d$n_candidates))
  }
  if (!is.null(d$n_basis)) {
    cat(sprintf("%-30s %s\n", "Basis coefficients", d$n_basis))
  }
  if (!is.null(d$coef_mean)) {
    cat(sprintf(
      "%-30s %s\n", "Coefficient matrix",
      paste(d$coef_mean, collapse = " x ")
    ))
  }
  if (!is.null(d$expected_vcov)) {
    cat(sprintf(
      "%-30s %s\n", "Expected joint covariance",
      paste(d$expected_vcov, collapse = " x ")
    ))
  }
  if (!is.null(d$supplied_vcov)) {
    cat(sprintf(
      "%-30s %s\n", "Supplied joint covariance",
      paste(d$supplied_vcov, collapse = " x ")
    ))
  }

  cat("\n")
  for (i in seq_len(nrow(x$checks))) {
    cat(sprintf(
      "%-8s %-28s %s\n",
      x$checks$status[i], x$checks$item[i], x$checks$message[i]
    ))
  }

  cat("\nOverall status: ", x$status, "\n\n", sep = "")
  cat(x$conditionality, "\n", sep = "")
  invisible(x)
}
