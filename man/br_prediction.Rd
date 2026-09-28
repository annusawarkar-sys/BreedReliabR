\name{br_prediction}
\alias{br_prediction}
\title{Construct a genomic prediction object}
\usage{
br_prediction(candidates, coef_mean, coef_vcov,
  basis_names = colnames(coef_mean), source = NULL,
  metadata = list(), tol = 1e-08)
}
\arguments{
  \item{candidates}{Unique candidate identifiers.}
  \item{coef_mean}{Numeric matrix with one row per candidate and one column per environmental basis coefficient.}
  \item{coef_vcov}{Full prediction-error covariance matrix for all candidate coefficients, stacked candidate by candidate.}
  \item{basis_names}{Optional names for the environmental basis coefficients.}
  \item{source}{Optional label identifying the source prediction model.}
  \item{metadata}{Optional named list of metadata.}
  \item{tol}{Numerical tolerance used for symmetry and positive-semidefinite checks.}
}
\value{An object of class \code{br_prediction}.}
\description{Creates and validates the model-agnostic prediction object used by BreedReliabR. The full joint prediction covariance is retained because advancement probabilities depend on covariance among candidate coefficients and candidates.}
\details{The covariance must be a finite symmetric positive-semidefinite matrix in candidate-major order: all basis coefficients for candidate 1, then all coefficients for candidate 2, and so on. It is the full prediction-error covariance supplied by an external fitting workflow. Do not substitute marginal standard errors or a diagonal matrix unless that is the validated covariance from the upstream model. BreedReliabR does not fit or validate that model.}
\seealso{\code{\link{br_tpe}}, \code{\link{br_advance}}, \code{\link{br_compare}}}

\examples{
data(maize_demo)
p <- do.call(br_prediction, maize_demo$prediction_inputs)
p
}
