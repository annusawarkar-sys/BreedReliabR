make_fixture <- function(zero_pred = FALSE, zero_env = FALSE) {
  ids <- c("G1", "G2", "G3", "G4")
  mu <- rbind(
    c(1.0,  0.30),
    c(0.9, -0.10),
    c(0.8,  0.20),
    c(0.7, -0.25)
  )
  colnames(mu) <- c("intercept", "stress")
  P <- diag(rep(c(0.12, 0.08), 4))
  # Add candidate covariance while retaining PSD.
  for (a in 1:4) for (b in 1:4) if (a != b) {
    P[(a-1)*2+1, (b-1)*2+1] <- 0.015
    P[(a-1)*2+2, (b-1)*2+2] <- 0.010
  }
  if (zero_pred) P[,] <- 0
  pred <- br_prediction(ids, mu, P)
  if (zero_env) {
    X <- matrix(c(1, 0, 1, 0, 1, 0), ncol = 2, byrow = TRUE)
  } else {
    X <- rbind(c(1, -1), c(1, 0), c(1, 1))
  }
  colnames(X) <- c("intercept", "stress")
  tpe <- br_tpe(X, c(0.25, 0.5, 0.25))
  list(pred = pred, tpe = tpe)
}
