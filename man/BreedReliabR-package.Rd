\name{BreedReliabR-package}
\alias{BreedReliabR}
\alias{BreedReliabR-package}
\docType{package}
\title{Decision Reliability for Genomic Genotype Advancement Across Target Environments}
\description{A model-agnostic decision-reliability layer for genotype advancement from externally fitted genomic or genotype-by-environment prediction models. It propagates correlated prediction uncertainty together with finite sampling of a user-specified target population of environments.}
\details{The package does not fit genomic prediction models. It consumes predicted environmental-response coefficients and their full joint covariance, then evaluates uncertainty and advancement reliability conditional on a specified target population of environments. Use \code{br_check_inputs()} as a non-destructive structural preflight before constructing prediction and TPE objects. The package vignettes provide a beginner hand-off, a transparent genomic GxE reference workflow, and a model-integration guide.}
\author{Ashutosh Sawarkar and Santosh Patil}
