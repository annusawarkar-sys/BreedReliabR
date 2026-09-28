\name{br_curve}
\alias{br_curve}
\title{Compute uncertainty and reliability over future network sizes}
\usage{br_curve(prediction, tpe, H = c(1L, 3L, 5L, 10L, 20L),
  k, nsim = 5000L, seed = NULL, tol = 1e-10)}
\arguments{
\item{prediction}{A \code{br_prediction} object.}
\item{tpe}{A compatible \code{br_tpe} object.}
\item{H}{Nonempty numeric vector of positive integers. Duplicates are removed preserving first occurrence order.}
\item{k}{Number advanced.}
\item{nsim}{Monte Carlo draws per stochastic method and H.}
\item{seed}{Optional seed reused at every H and method.}
\item{tol}{Tolerance passed to the advancement core.}
}
\description{Combines \code{br_omega} and M0--M3 comparisons for user-specified H values without smoothing or thresholds.}
\details{H counts independent future draws with replacement from the fixed TPE.
It is not training size. Omega scales as 1/H for fixed nonzero prediction variance;
ranking reliability need not be monotone. Reliability is an expected retained
fraction, not exact-set recovery. M0 reliability is NA. With a fixed seed M1
is identical across H. Shared seeds induce dependence across evaluations; no
paired precision or set-level MCSE is claimed. Memory and time grow with H,
nsim and candidate count. Infinite Omega values remain in returned tables.}
\value{A \code{br_curve} list with \code{H}, \code{omega} (core object),
\code{summary}, \code{candidates}, \code{comparisons} (named by H),
\code{seed}, and \code{conditionality}.}
\seealso{\code{\link{br_advance}}, \code{\link{br_compare}}, \code{\link{br_omega}}}
\examples{
data(maize_demo)
p <- do.call(br_prediction, maize_demo$prediction_inputs)
t <- br_tpe(maize_demo$tpe_basis, maize_demo$tpe_states$weight)
x <- br_curve(p, t, H = c(1, 5), k = 3, nsim = 100, seed = 2)
summary(x)
plot(x)
}
