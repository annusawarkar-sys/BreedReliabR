\name{br_advance}
\alias{br_advance}
\title{Estimate genotype advancement probabilities}
\usage{
br_advance(prediction, tpe, H = 5L, k, nsim = 5000L,
  method = c("M3", "M1", "M2", "M0"), seed = NULL,
  tol = 1e-10)
}
\arguments{
  \item{prediction}{A \code{br_prediction} object.}
  \item{tpe}{A \code{br_tpe} object.}
  \item{H}{Number of future environments.}
  \item{k}{Number of candidates to advance.}
  \item{nsim}{Number of Monte Carlo draws for M1--M3.}
  \item{method}{One of \code{"M0"}, \code{"M1"}, \code{"M2"}, or \code{"M3"}.}
  \item{seed}{Optional random seed for reproducibility.}
  \item{tol}{Numerical tolerance.}
}
\value{An object of class \code{br_advancement} containing expected merit, advancement probabilities, Monte Carlo standard errors, selected sets and selected-set reliability.}
\description{Implements point ranking (M0), prediction-uncertainty propagation (M1), finite-TPE uncertainty with fixed predictions (M2), or joint propagation of correlated prediction uncertainty and finite-TPE sampling (M3).}
\details{Advancement probabilities are conditional on the supplied predictive
distribution, TPE specification, and H; they are not guaranteed to be empirically
calibrated. Set reliability is the expected retained fraction (the mean advancement
probability over members of the specified set), not the probability of recovering
the entire set. M0 returns deterministic 0/1 selection indicators in
\code{p_advance}, not probability forecasts, and returns NA set reliability.
Candidate MCSE quantifies simulation error conditional on the supplied distribution,
not empirical prediction accuracy.
The probability-selected set is selected and evaluated with the same simulations.
Future environments are independent draws with replacement from fixed TPE weights,
independent of the Gaussian coefficient uncertainty. Candidate IDs break ties.
A supplied seed sets and advances the session RNG state.}

\seealso{\code{\link{br_prediction}}, \code{\link{br_tpe}}, \code{\link{br_compare}}, \code{\link{br_curve}}}

\examples{
data(maize_demo)
p <- do.call(br_prediction, maize_demo$prediction_inputs)
t <- br_tpe(maize_demo$tpe_basis, maize_demo$tpe_states$weight)
br_advance(p, t, H = 3, k = 3, nsim = 100, seed = 1)
}
