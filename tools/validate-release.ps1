param(
  [string]$RHome = "C:\Program Files\R\R-4.6.1",
  [string]$ArtifactDir = (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "validation-output"),
  [string]$Repository = "https://cloud.r-project.org"
)

$ErrorActionPreference = "Stop"
$packageRoot = Split-Path -Parent $PSScriptRoot
$rExe = Join-Path $RHome "bin\R.exe"
$rscript = Join-Path $RHome "bin\Rscript.exe"
if (!(Test-Path -LiteralPath $rExe) -or !(Test-Path -LiteralPath $rscript)) {
  throw "R 4.6.1 was not found at $RHome"
}

New-Item -ItemType Directory -Force -Path $ArtifactDir | Out-Null
$library = Join-Path $ArtifactDir "clean-library"
$checkDir = Join-Path $ArtifactDir "check"
New-Item -ItemType Directory -Force -Path $library, $checkDir | Out-Null
$env:R_LIBS_USER = $library
$env:R_LIBS_SITE = ""
$bundledPandoc = "C:\Program Files\RStudio\resources\app\bin\quarto\bin\tools"
if (Test-Path -LiteralPath (Join-Path $bundledPandoc "pandoc.exe")) {
  $env:RSTUDIO_PANDOC = $bundledPandoc
}
foreach ($localeName in @("LC_ALL", "LC_COLLATE", "LC_CTYPE", "LC_MONETARY", "LC_TIME")) {
  Remove-Item -Path "Env:$localeName" -ErrorAction SilentlyContinue
}

& $rscript --vanilla -e "needed <- c('testthat','knitr','rmarkdown'); missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly=TRUE)]; if (length(missing)) install.packages(missing, repos='$Repository', lib=Sys.getenv('R_LIBS_USER'))" *> (Join-Path $ArtifactDir "dependency-install.log")
if ($LASTEXITCODE -ne 0) { throw "Declared suggested dependencies did not install; inspect dependency-install.log" }

& $rExe CMD INSTALL --preclean --clean --install-tests --library="$library" $packageRoot *> (Join-Path $ArtifactDir "install.log")
if ($LASTEXITCODE -ne 0) { throw "Package installation failed; inspect install.log" }

$env:NOT_CRAN = "true"
& $rscript --vanilla -e "testthat::test_package('BreedReliabR', reporter='summary')" *> (Join-Path $ArtifactDir "testthat.log")
$testExit = $LASTEXITCODE
Remove-Item Env:NOT_CRAN -ErrorAction SilentlyContinue
if ($testExit -ne 0) { throw "The installed package test suite failed; inspect testthat.log" }

Push-Location $ArtifactDir
try {
  & $rExe CMD build $packageRoot *> (Join-Path $ArtifactDir "build.log")
  if ($LASTEXITCODE -ne 0) { throw "Source build failed; inspect build.log" }
} finally { Pop-Location }

$tarball = Get-ChildItem -LiteralPath $ArtifactDir -Filter "BreedReliabR_0.1.0.tar.gz" -File | Select-Object -First 1
if (!$tarball) { throw "Expected BreedReliabR_0.1.0.tar.gz was not created" }
& $rExe CMD check --as-cran --library="$library" --output="$checkDir" $tarball.FullName *> (Join-Path $ArtifactDir "R-CMD-check.log")
if ($LASTEXITCODE -ne 0) { throw "R CMD check did not finish cleanly; inspect R-CMD-check.log and check directory" }

Write-Output "Release validation completed. Review the full check log and every NOTE before release."
