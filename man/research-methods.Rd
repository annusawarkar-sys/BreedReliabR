\name{research-methods}
\alias{print.br_comparison}
\alias{summary.br_comparison}
\alias{plot.br_comparison}
\alias{print.br_curve}
\alias{summary.br_curve}
\alias{plot.br_curve}
\alias{print.br_support}
\alias{summary.br_support}
\alias{plot.br_support}
\title{Display research-facing results}
\usage{
\method{print}{br_comparison}(x, ...)
\method{summary}{br_comparison}(object, ...)
\method{plot}{br_comparison}(x, ...)
\method{print}{br_curve}(x, ...)
\method{summary}{br_curve}(object, ...)
\method{plot}{br_curve}(x, type = c("reliability", "omega"),
  set = c("expected_merit", "probability"), ...)
\method{print}{br_support}(x, ...)
\method{summary}{br_support}(object, ...)
\method{plot}{br_support}(x, ...)
}
\arguments{
\item{x, object}{An object of the corresponding class.}
\item{type}{Plot expected retained fraction or median candidate Omega.}
\item{set}{Which selected-set reliability to plot.}
\item{...}{Additional print or graphics arguments, excluding arguments already set by the method. Ignored by summary methods.}
}
\description{Compact tabular and base-graphics displays. Curve plots sort H for display; returned input order is preserved. Support plots mark marginal departures in red and show the maximum training nearest-neighbour distance as a dashed reference.}
\details{Nonfinite distances or Omega values are omitted with a warning; if none are finite plotting stops with an error. Inspect the returned tables for those values. M0 is omitted from reliability plots because it does not estimate reliability.}
\value{Print and plot methods invisibly return x. Summary methods return the summary data frame, or for curves a list containing reliability and Omega summary tables.}
