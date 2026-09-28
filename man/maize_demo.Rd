\name{maize_demo}
\alias{maize_demo}
\docType{data}
\title{Explicitly simulated maize advancement demonstration}
\description{A synthetic yield scenario for demonstrating import and analysis. No real observations or fitted genomic model are included.}
\usage{data(maize_demo)}
\format{A list with: \describe{
\item{training_environments}{12 rows: environment ID, flowering water-deficit fraction and hot days during flowering.}
\item{training_basis}{12 by 3 matrix: intercept, water (deficit minus 0.35 divided by 0.20), heat (days minus 7 divided by 5).}
\item{training_phenotypes}{240 rows: 10 training genotype IDs by 12 environments by two replicates, with simulated yield in t/ha.}
\item{candidates}{Eight distinct unphenotyped candidate IDs and false phenotyped indicators.}
\item{prediction_inputs}{Arguments to br_prediction: IDs, 8 by 3 coefficient means, 24 by 24 joint candidate-major prediction covariance, source and metadata.}
\item{tpe_states}{Five states with IDs, water-deficit fraction, hot days and fixed weights.}
\item{tpe_basis}{Five by three matrix using the training transformations.}
\item{provenance}{Simulation indicator, seed and explanation.}
}}
\details{The extreme hot-dry state is deliberately outside the training ranges.
Yield coefficients reflect illustrative negative stress responses, not estimated
biological parameters. Prediction covariance is a positive definite Kronecker
construction with correlated candidates. Prediction inputs are stipulated, not
estimated from the illustrative training phenotypes. The reproducible generation
script is in inst/scripts/maize_demo.R in the source package and installed in scripts.}
\source{Generated for BreedReliabR with seed 260926; no external data.}
\examples{data(maize_demo)
str(maize_demo, max.level = 1)
}
