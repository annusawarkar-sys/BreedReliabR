# Development helper for the 0.1.2 template bundle.
# Run from this directory under native R, then verify the resulting RDS before release.

x <- read.csv("candidate_joint_PEV.csv", check.names = FALSE,
              stringsAsFactors = FALSE)
ids <- x[[1L]]
P <- as.matrix(x[-1L])
storage.mode(P) <- "double"
rownames(P) <- ids
colnames(P) <- names(x)[-1L]

stopifnot(
  identical(rownames(P), colnames(P)),
  isSymmetric(P, tol = 1e-12),
  min(eigen(P, symmetric = TRUE, only.values = TRUE)$values) >= 0
)

saveRDS(P, "candidate_joint_PEV.rds")
