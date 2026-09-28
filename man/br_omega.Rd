\name{br_omega}
\alias{br_omega}
\title{Quantify prediction versus finite-TPE uncertainty}
\usage{
br_omega(prediction, tpe, H = c(1L, 3L, 5L, 10L, 20L))
}
\arguments{
  \item{prediction}{A \code{br_prediction} object.}
  \item{tpe}{A \code{br_tpe} object.}
  \item{H}{Positive integer vector giving future testing-network sizes.}
}
\value{An object of class \code{br_omega} containing candidate-level prediction variance, finite-TPE variance and their ratio for each requested value of \code{H}, plus summary statistics.}
\description{Computes the decision-reliability diagnostic that contrasts uncertainty in predicted TPE-average genetic merit with uncertainty arising from finite representation of the specified target population of environments.}
\details{Omega is the ratio of the finite-TPE environmental variance to prediction variance for each candidate and requested H. It is a relative uncertainty diagnostic, not a probability, calibration measure, or universal threshold for choosing H or a method. Its interpretation is conditional on the supplied prediction covariance and TPE.}
\seealso{\code{\link{br_tpe}}, \code{\link{br_advance}}, \code{\link{br_curve}}}

\examples{
data(maize_demo)
p <- do.call(br_prediction, maize_demo$prediction_inputs)
t <- br_tpe(maize_demo$tpe_basis, maize_demo$tpe_states$weight)
br_omega(p, t, H = c(1, 5))
}
