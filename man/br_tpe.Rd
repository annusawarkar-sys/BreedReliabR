\name{br_tpe}
\alias{br_tpe}
\title{Define a target population of environments}
\usage{
br_tpe(basis, weights = NULL, state_id = NULL, metadata = list())
}
\arguments{
  \item{basis}{Numeric matrix with one row per TPE state and environmental basis columns matching the prediction object.}
  \item{weights}{Non-negative state weights. Values are normalised to sum to one.}
  \item{state_id}{Optional unique identifiers for TPE states.}
  \item{metadata}{Optional named list of metadata.}
}
\value{An object of class \code{br_tpe}.}
\description{Defines the user-specified target population of environments used to evaluate finite-environment deployment uncertainty.}
\details{Weights are normalized to sum to one and describe the assumed distribution over supplied states. They are not automatically production-area or acreage weights. Conclusions are conditional on the chosen states, basis, and weights. Zero-weight states are retained for diagnostics but contribute no probability mass.}
\seealso{\code{\link{br_prediction}}, \code{\link{br_support}}, \code{\link{br_omega}}}

\examples{
data(maize_demo)
t <- br_tpe(maize_demo$tpe_basis, maize_demo$tpe_states$weight)
t
}
