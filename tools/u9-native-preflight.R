# Native-R preflight for the BreedReliabR 0.1.2 operational-usability candidate.
# Run from the package root before R CMD build/check.

package_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(package_root, "DESCRIPTION"))) {
  stop("Run this script from the BreedReliabR package root.", call. = FALSE)
}

template_dir <- file.path(package_root, "inst", "extdata", "templates")
generator <- file.path(template_dir, "generate_candidate_joint_PEV.R")
if (!file.exists(generator)) {
  stop("Template PEV generator is missing.", call. = FALSE)
}

old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(template_dir)
source("generate_candidate_joint_PEV.R", local = new.env(parent = globalenv()))
setwd(old_wd)

rds_file <- file.path(template_dir, "candidate_joint_PEV.rds")
if (!file.exists(rds_file)) {
  stop("candidate_joint_PEV.rds was not generated.", call. = FALSE)
}

P <- readRDS(rds_file)
stopifnot(
  is.matrix(P),
  is.numeric(P),
  identical(rownames(P), colnames(P)),
  isSymmetric(P, tol = 1e-12),
  min(eigen(P, symmetric = TRUE, only.values = TRUE)$values) >= 0
)

message("Template RDS generated and verified: ", rds_file)
message("Next: install/test the package, render all vignettes, then run R CMD check --as-cran.")
