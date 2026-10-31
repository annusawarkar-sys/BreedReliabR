# BreedReliabR 0.1.2 persistent native release gate.
#
# Run from the package root with a native R installation after the suggested
# dependencies (testthat, knitr, rmarkdown) and a working LaTeX/Pandoc setup
# are available. The script does not publish or tag a release.
#
# By default, validation artifacts are written to a persistent sibling
# directory named BreedReliabR-U12-validation-<platform>. Override this with
# the BREEDRELIABR_U12_ARTIFACT_DIR environment variable.

package_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(package_root, "DESCRIPTION"))) {
  stop("Run tools/u12-native-release-gate.R from the BreedReliabR package root.",
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

if (!rmarkdown::pandoc_available()) {
  stop("Pandoc is required to render the source vignettes.", call. = FALSE)
}

if (!nzchar(Sys.which("pdflatex"))) {
  stop(
    "A working LaTeX installation with pdflatex is required for the strict ",
    "R CMD check --as-cran release gate.",
    call. = FALSE
  )
}

version <- as.character(
  read.dcf(file.path(package_root, "DESCRIPTION"), fields = "Version")[1L, 1L]
)
if (!identical(version, "0.1.2")) {
  stop("Expected DESCRIPTION Version 0.1.2, found ", version, ".", call. = FALSE)
}

platform_tag <- gsub(
  "[^A-Za-z0-9._-]+",
  "-",
  paste(R.version$platform, paste(R.version$major, R.version$minor, sep = "."), sep = "-R")
)
default_artifact_root <- file.path(
  dirname(package_root),
  paste0("BreedReliabR-U12-validation-", platform_tag)
)
artifact_root <- Sys.getenv(
  "BREEDRELIABR_U12_ARTIFACT_DIR",
  unset = default_artifact_root
)
artifact_root <- normalizePath(
  artifact_root,
  winslash = "/",
  mustWork = FALSE
)

unlink(artifact_root, recursive = TRUE, force = TRUE)
dir.create(artifact_root, recursive = TRUE, showWarnings = FALSE)
lib <- file.path(artifact_root, "library")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)

old_libs <- .libPaths()
on.exit(.libPaths(old_libs), add = TRUE)
.libPaths(c(lib, old_libs))

writeLines(
  capture.output(sessionInfo()),
  file.path(artifact_root, "sessionInfo.txt")
)
writeLines(
  c(
    paste0("Package root: ", package_root),
    paste0("Version: ", version),
    paste0("Platform: ", R.version$platform),
    paste0("R version: ", R.version.string),
    paste0("Pandoc: ", rmarkdown::pandoc_version()),
    paste0("pdflatex: ", Sys.which("pdflatex"))
  ),
  file.path(artifact_root, "environment.txt")
)

message("[1/8] Generate and verify canonical template RDS")
source(
  file.path(package_root, "tools", "u9-native-preflight.R"),
  local = new.env(parent = globalenv())
)

r_bin <- file.path(
  R.home("bin"),
  if (.Platform$OS.type == "windows") "R.exe" else "R"
)
rscript_bin <- file.path(
  R.home("bin"),
  if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"
)

message("[2/8] Install package with tests")
install_log <- file.path(artifact_root, "install.log")
status <- system2(
  r_bin,
  c(
    "CMD", "INSTALL", "--preclean", "--clean", "--install-tests",
    paste0("--library=", shQuote(lib)),
    shQuote(package_root)
  ),
  stdout = install_log,
  stderr = install_log
)
if (!identical(status, 0L)) {
  stop("R CMD INSTALL failed. See ", install_log, call. = FALSE)
}

message("[3/8] Run installed-package testthat suite")
test_log <- file.path(artifact_root, "testthat.log")
test_expr <- paste(
  "library(testthat);",
  "library(BreedReliabR);",
  "test_package('BreedReliabR', reporter='summary')"
)
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

message("[4/8] Render every source vignette explicitly")
vignette_dir <- file.path(package_root, "vignettes")
vignette_files <- sort(list.files(
  vignette_dir,
  pattern = "\\.Rmd$",
  full.names = TRUE
))
if (!length(vignette_files)) {
  stop("No source vignettes found.", call. = FALSE)
}
render_dir <- file.path(artifact_root, "rendered-vignettes")
dir.create(render_dir, recursive = TRUE, showWarnings = FALSE)
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

message("[5/8] Build source package")
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

message("[6/8] Run R CMD check --as-cran")
check_log <- file.path(artifact_root, "R-CMD-check.log")
check_dir <- file.path(artifact_root, "check")
dir.create(check_dir, showWarnings = FALSE)
setwd(check_dir)
status <- system2(
  r_bin,
  c("CMD", "check", "--as-cran", shQuote(tarball)),
  stdout = check_log,
  stderr = check_log,
  env = c(paste0("R_LIBS_USER=", lib))
)
if (!identical(status, 0L)) {
  stop("R CMD check --as-cran failed. See ", check_log, call. = FALSE)
}

message("[7/8] Require a clean Status: OK")
check_dirs <- list.dirs(check_dir, recursive = FALSE, full.names = TRUE)
check_dirs <- check_dirs[grepl("\\.Rcheck$", check_dirs)]
if (length(check_dirs) != 1L) {
  stop("Expected exactly one .Rcheck directory.", call. = FALSE)
}
check_file <- file.path(check_dirs, "00check.log")
if (!file.exists(check_file)) {
  stop("00check.log is missing.", call. = FALSE)
}
log_lines <- readLines(check_file, warn = FALSE)
status_line <- grep("^Status:", log_lines, value = TRUE)
if (length(status_line) != 1L) {
  stop("Could not identify final check status.", call. = FALSE)
}
message(status_line)
if (!identical(trimws(status_line), "Status: OK")) {
  stop(
    "R CMD check completed with ERROR, WARNING, or NOTE. Review ",
    check_file,
    call. = FALSE
  )
}

file.copy(
  check_file,
  file.path(artifact_root, "00check.log"),
  overwrite = TRUE
)

message("[8/8] Write persistent PASS marker")
pass_file <- file.path(artifact_root, "U12_NATIVE_PASS.txt")
writeLines(
  c(
    "BreedReliabR 0.1.2 U12 native release gate: PASS",
    paste0("R: ", R.version.string),
    paste0("Platform: ", R.version$platform),
    "R CMD check --as-cran: Status: OK",
    paste0("Source tarball: ", basename(tarball)),
    paste0("Vignettes rendered: ", length(vignette_files))
  ),
  pass_file
)

message("U12 native release gate PASS")
message("Persistent artifacts: ", artifact_root)
message("Source tarball: ", tarball)
message("PASS marker: ", pass_file)
