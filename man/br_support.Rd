\name{br_support}
\alias{br_support}
\title{Diagnose geometric environmental support of a specified TPE}
\usage{br_support(tpe, training_basis, tol = 1e-10)}
\arguments{
\item{tpe}{A \code{br_tpe} object.}
\item{training_basis}{Finite numeric matrix with at least two rows and identical basis column names and order to the TPE. Use the same transformations for training and TPE.}
\item{tol}{Non-negative absolute tolerance for marginal range departures, in each supplied basis column's units.}
}
\description{Reports marginal range departures and nearest-training Euclidean distances standardized by training sample standard deviations. It does not certify biological correctness of a TPE.}
\details{These are geometric diagnostics in the supplied environmental basis. A state outside marginal training ranges or farther away than training leave-one-out neighbours may be extrapolative, but the diagnostics do not prove biological validity, prediction accuracy, or calibration. Correlation among basis dimensions can affect distances. Exactly constant training columns are excluded from finite distances.
Departures greater than tol in such columns produce infinite distance and an
explicit constant-mismatch flag. Other columns use their sample standard deviations.
The largest leave-one-out nearest-neighbour training distance is an empirical
reference, not a calibrated cutoff. Duplicate training rows have zero nearest
distance. Correlated or redundant columns can distort distances; marginal ranges
do not describe a joint convex hull. Zero-weight states are diagnosed but do not
contribute to weighted masses. All-constant training spaces are supported.
Geometric support does not establish model calibration, biological relevance,
or defensibility of the supplied weights.}
\value{A list of per-state diagnostics, weighted summaries, training ranges,
standardized nearest-neighbour distances, and a conditionality statement.}
\examples{
data(maize_demo)
t <- br_tpe(maize_demo$tpe_basis, maize_demo$tpe_states$weight)
s <- br_support(t, maize_demo$training_basis)
s$states
plot(s)
}
\seealso{\code{\link{br_tpe}}, \code{\link{br_omega}}, \code{\link{br_curve}}}
