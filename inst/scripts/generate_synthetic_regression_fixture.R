# Run from the BreedReliabR source directory to regenerate the small
# non-G2F M0-M3 reference probabilities used by test-adapter-regression.R.
source(file.path("R", "utils.R"))
source(file.path("R", "prediction.R"))
source(file.path("R", "tpe.R"))
source(file.path("R", "omega.R"))
source(file.path("R", "advance.R"))

ids <- c("G1", "G2", "G3", "G4")
mu <- rbind(c(1.0, .30), c(.9, -.10), c(.8, .20), c(.7, -.25))
colnames(mu) <- c("intercept", "stress")
P <- diag(rep(c(.12, .08), 4))
for (a in 1:4) for (b in 1:4) if (a != b) {
  P[(a - 1) * 2 + 1, (b - 1) * 2 + 1] <- .015
  P[(a - 1) * 2 + 2, (b - 1) * 2 + 2] <- .010
}
prediction <- br_prediction(ids, mu, P)
X <- rbind(c(1, -1), c(1, 0), c(1, 1))
colnames(X) <- c("intercept", "stress")
tpe <- br_tpe(X, c(.25, .5, .25))

result <- do.call(rbind, lapply(c("M0", "M1", "M2", "M3"), function(method) {
  fit <- br_advance(prediction, tpe, H = 5, k = 2, nsim = 2500,
                    method = method, seed = 321)
  data.frame(method = method, candidate = fit$candidates$candidate,
             p_advance = fit$candidates$p_advance, stringsAsFactors = FALSE)
}))
dir.create(file.path("tests", "testthat", "fixtures"), recursive = TRUE,
           showWarnings = FALSE)
utils::write.csv(result,
  file.path("tests", "testthat", "fixtures", "method-reference.csv"),
  row.names = FALSE)
