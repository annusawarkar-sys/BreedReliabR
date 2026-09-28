\name{br_compare}
\alias{br_compare}
\title{Compare four advancement uncertainty scenarios}
\usage{br_compare(prediction, tpe, H = 5L, k, nsim = 5000L,
  seed = NULL, tol = 1e-10)}
\arguments{
\item{prediction}{A \code{br_prediction} object.}
\item{tpe}{A \code{br_tpe} object with the same basis.}
\item{H}{Positive integer number of independent future environments.}
\item{k}{Number of candidates advanced.}
\item{nsim}{Monte Carlo draws per stochastic scenario, at least two.}
\item{seed}{Optional seed, passed unchanged to each core call.}
\item{tol}{Numerical tolerance passed to \code{br_advance}.}
}
\description{Runs M0, M1, M2 and M3 with the same prediction, TPE, H and k using the frozen advancement implementation.}
\details{M0 ranks expected merit; M1 propagates prediction uncertainty; M2 propagates finite-environment sampling with fixed coefficients; M3 propagates both.
Set reliability means expected retained fraction, not exact-set recovery probability.
M0 reliability is NA. The probability-selected set is evaluated using the same
draws that selected it, so its estimated reliability can be optimistically selected.
Candidate MCSE is Monte Carlo error only. A common seed makes calls reproducible
but does not establish a paired Monte Carlo comparison. As in the core, a supplied
seed changes the session RNG state. Results are conditional on the inputs.}
\value{A \code{br_comparison} list with \code{summary} (one row per method),
\code{candidates} (long candidate table with method and H), \code{analyses}
(named core results), \code{seed}, and \code{conditionality}.}
\seealso{\code{\link{br_advance}}, \code{\link{br_curve}}, \code{\link{br_omega}}}
\examples{
data(maize_demo)
p <- do.call(br_prediction, maize_demo$prediction_inputs)
t <- br_tpe(maize_demo$tpe_basis, maize_demo$tpe_states$weight)
x <- br_compare(p, t, H = 3, k = 3, nsim = 100, seed = 1)
summary(x)
}
