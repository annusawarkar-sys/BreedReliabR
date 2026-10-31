# BreedReliabR 0.1.2 native release gate.
# Run from the package root with a native R installation after suggested
# dependencies (testthat, knitr, rmarkdown) are available.
#
# This script does not publish or tag a release. It prepares the canonical
# template RDS, installs the package into an isolated temporary library, runs
# the installed-package tests, renders every vignette, builds the source
# package, and runs R CMD check --as-cran. Any non-zero command status stops.

package_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(package_root, "DESCRIPTION"))) {
  stop("Run tools/u11-native-release-gate.R from the BreedReliabR package root.",
       call. = FALSE)
}

needed <- c("testthat", "knitr", "rmarkdown")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop(
    "Missing suggested package(s): ", paste(missing, collapse = ", "),
    ". Install them before running the native release gate.",
    call. = FALSE
  )
}

version <- as.character(read.dcf(file.path(package_root, "DESCRIPTION"),
                                 fields = "Version")[1L, 1L])
if (!identical(version, "0.1.2")) {
  stop("Expected DESCRIPTION Version 0.1.2, found ", version, ".", call. = FALSE)
}

artifact_root <- file.path(tempdir(), paste0("BreedReliabR-u11-", version))
unlink(artifact_root, recursive = TRUE, force = TRUE)
dir.create(artifact_root, recursive = TRUE, showWarnings = FALSE)
lib <- file.path(artifact_root, "library")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)

old_libs <- .libPaths()
on.exit(.libPaths(old_libs), add = TRUE)
.libPaths(c(lib, old_libs))

message("[1/7] Generate and verify canonical template RDS")
source(file.path(package_root, "tools", "u9-native-preflight.R"),
       local = new.env(parent = globalenv()))

message("[2/7] Install package with tests")
r_bin <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R")
install_log <- file.path(artifact_root, "install.log")
status <- system2(
  r_bin,
  c("CMD", "INSTALL", "--preclean", "--clean", "--install-tests",
    paste0("--library=", shQuote(lib)), shQuote(package_root)),
  stdout = install_log,
  stderr = install_log
)
if (!identical(status, 0L)) {
  stop("R CMD INSTALL failed. See ", install_log, call. = FALSE)
}

message("[3/7] Run installed-package testthat suite")
test_log <- file.path(artifact_root, "testthat.log")
test_expr <- sprintf(
  "library(testthat); library(BreedReliabR); test_package('BreedReliabR', reporter='summary')"
)
rscript_bin <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
env <- c(paste0("R_LIBS_USER=", lib), "NOT_CRAN=true")
status <- system2(
  rscript_bin,
  c("--vanilla", "-e", shQuote(test_expr)),
  stdout = test_log,
  stderr = test_log,
  env = env
)
if (!identical(status, 0L)) {
  stop("testthat suite failed. See ", test_log, call. = FALSE)
}

message("[4/7] Render every source vignette explicitly")
vignette_dir <- file.path(package_root, "vignettes")
vignette_files <- list.files(vignette_dir, pattern = "\\.Rmd$", full.names = TRUE)
if (!length(vignette_files)) stop("No source vignettes found.", call. = FALSE)
render_dir <- file.path(artifact_root, "rendered-vignettes")
dir.create(render_dir, recursive = TRUE, showWarnings = FALSE)
old_env <- Sys.getenv("R_LIBS_USER", unset = NA_character_)
on.exit({
  if (is.na(old_env)) Sys.unsetenv("R_LIBS_USER") else Sys.setenv(R_LIBS_USER = old_env)
}, add = TRUE)
Sys.setenv(R_LIBS_USER = lib)
for (f in vignette_files) {
  message("  rendering ", basename(f))
  rmarkdown::render(
    input = f,
    output_dir = render_dir,
    quiet = TRUE,
    envir = new.env(parent = globalenv())
  )
}
rendered <- list.files(render_dir, pattern = "\\.html$", full.names = TRUE)
if (length(rendered) != length(vignette_files)) {
  stop("Not all vignettes produced an HTML output.", call. = FALSE)
}

message("[5/7] Build source package")
build_log <- file.path(artifact_root, "build.log")
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(artifact_root)
status <- system2(
  r_bin,
  c("CMD", "build", shQuote(package_root)),
  stdout = build_log,
  stderr = build_log
)
if (!identical(status, 0L)) {
  stop("R CMD build failed. See ", build_log, call. = FALSE)
}

tarball <- file.path(artifact_root, paste0("BreedReliabR_", version, ".tar.gz"))
if (!file.exists(tarball)) {
  stop("Expected source tarball was not created: ", tarball, call. = FALSE)
}

message("[6/7] Run R CMD check --as-cran")
check_log <- file.path(artifact_root, "R-CMD-check.log")
check_dir <- file.path(artifact_root, "check")
dir.create(check_dir, showWarnings = FALSE)
setwd(check_dir)
status <- system2(
  r_bin,
  c("CMD", "check", "--as-cran", paste0("--library=", shQuote(lib)), shQuote(tarball)),
  stdout = check_log,
  stderr = check_log
)
if (!identical(status, 0L)) {
  stop("R CMD check --as-cran failed. See ", check_log, call. = FALSE)
}

message("[7/7] Inspect check summary")
check_dirs <- list.dirs(check_dir, recursive = FALSE, full.names = TRUE)
check_dirs <- check_dirs[grepl("\\.Rcheck$", check_dirs)]
if (length(check_dirs) != 1L) {
  stop("Expected exactly one .Rcheck directory.", call. = FALSE)
}
check_file <- file.path(check_dirs, "00check.log")
if (!file.exists(check_file)) stop("00check.log is missing.", call. = FALSE)
log_lines <- readLines(check_file, warn = FALSE)
status_line <- grep("^Status:", log_lines, value = TRUE)
if (length(status_line) != 1L) stop("Could not identify final check status.", call. = FALSE)
message(status_line)
if (!grepl("Status: OK", status_line, fixed = TRUE)) {
  stop("R CMD check completed with ERROR, WARNING, or NOTE. Review ", check_file,
       call. = FALSE)
}

message("U11 native release gate PASS")
message("Artifacts are in: ", artifact_root)
message("Source tarball: ", tarball)
