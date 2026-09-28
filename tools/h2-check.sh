#!/usr/bin/env bash
set -euo pipefail
PKG_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
PARENT="$(dirname "$PKG_DIR")"
PKG_NAME="$(basename "$PKG_DIR")"
cd "$PARENT"
command -v R >/dev/null || { echo "R is not installed" >&2; exit 127; }
command -v Rscript >/dev/null || { echo "Rscript is not installed" >&2; exit 127; }
Rscript -e 'if (!requireNamespace("testthat", quietly=TRUE)) stop("testthat is required for H2")'
R CMD INSTALL --preclean --clean "$PKG_DIR"
NOT_CRAN=true Rscript -e "library(BreedReliabR); testthat::test_dir(file.path('$PKG_DIR','tests','testthat'))"
R CMD build "$PKG_DIR"
TARBALL=$(ls -t ${PKG_NAME}_*.tar.gz | head -1)
R CMD check --as-cran "$TARBALL"
echo "H2 native check completed: $TARBALL"
