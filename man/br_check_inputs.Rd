\name{br_check_inputs}
\alias{br_check_inputs}
\title{Check BreedReliabR input compatibility}
\usage{
br_check_inputs(
  candidates,
  coef_mean,
  coef_vcov,
  basis_names = colnames(coef_mean),
  tpe_basis = NULL,
  tpe_weights = NULL,
  training_basis = NULL,
  k = NULL,
  H = NULL,
  tol = 1e-08
)
}
\arguments{
\item{candidates}{Candidate identifiers.}
\item{coef_mean}{Numeric \eqn{n \times p} matrix of candidate coefficient means.}
\item{coef_vcov}{Numeric \eqn{np \times np} full joint coefficient covariance.}
\item{basis_names}{Character vector of environmental-basis names.}
\item{tpe_basis}{Optional numeric matrix of target-environment basis values.}
\item{tpe_weights}{Optional non-negative target-state weights.}
\item{training_basis}{Optional numeric training-environment basis matrix.}
\item{k}{Optional fixed number of candidates to advance.}
\item{H}{Optional positive integer value or vector describing future TPE representation.}
\item{tol}{Numerical tolerance used for structural covariance checks.}
}
\value{An object of class \code{br_input_check} containing an overall status, dimensions, a table of checks, and a conditionality statement.}
\description{Performs a non-destructive structural audit of candidate coefficient predictions, their full joint covariance, and optional target-environment and decision inputs before BreedReliabR objects are constructed.}
\details{
The function diagnoses structural compatibility but does not repair or reorder inputs. Canonical covariance labels use \code{candidate__basis} in candidate-major order. If covariance dimension names are absent or non-canonical, the function reports that ordering cannot be verified automatically.

The check does not validate the upstream prediction model, the adequacy of its covariance, the biological definition of the target population of environments, or empirical probability calibration. Positive TPE weights need not already sum to one because \code{br_tpe()} normalises them.
}
\examples{
ids <- c("G1", "G2")
mu <- matrix(c(1, 0.2, 0.9, -0.1), nrow = 2, byrow = TRUE,
             dimnames = list(ids, c("intercept", "stress")))
nm <- c("G1__intercept", "G1__stress", "G2__intercept", "G2__stress")
P <- diag(0.1, 4)
dimnames(P) <- list(nm, nm)
X <- matrix(c(1, -1, 1, 1), nrow = 2, byrow = TRUE,
            dimnames = list(c("E1", "E2"), c("intercept", "stress")))
br_check_inputs(ids, mu, P, tpe_basis = X, k = 1, H = 3)
}
\seealso{\code{\link{br_prediction}}, \code{\link{br_tpe}}, \code{\link{br_advance}}}
