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

& $rscript --vanilla (Join-Path $packageRoot "tools\u9-native-preflight.R") *> (Join-Path $ArtifactDir "template-preflight.log")
if ($LASTEXITCODE -ne 0) { throw "Template preflight failed; inspect template-preflight.log" }

& $rExe CMD INSTALL --preclean --clean --install-tests --library="$library" $packageRoot *> (Join-Path $ArtifactDir "install.log")
if ($LASTEXITCODE -ne 0) { throw "Package installation failed; inspect install.log" }

$env:NOT_CRAN = "true"
& $rscript --vanilla -e "testthat::test_package('BreedReliabR', reporter='summary')" *> (Join-Path $ArtifactDir "testthat.log")
$testExit = $LASTEXITCODE
Remove-Item Env:NOT_CRAN -ErrorAction SilentlyContinue
if ($testExit -ne 0) { throw "The installed package test suite failed; inspect testthat.log" }

$renderDir = Join-Path $ArtifactDir "rendered-vignettes"
New-Item -ItemType Directory -Force -Path $renderDir | Out-Null
$renderExpr = "files <- list.files(file.path('$($packageRoot -replace '\\','/')','vignettes'), pattern='\\.Rmd$', full.names=TRUE); out <- '$($renderDir -replace '\\','/')'; for (f in files) rmarkdown::render(f, output_dir=out, quiet=TRUE, envir=new.env(parent=globalenv())); stopifnot(length(list.files(out, pattern='\\.html$')) == length(files))"
& $rscript --vanilla -e $renderExpr *> (Join-Path $ArtifactDir "vignette-render.log")
if ($LASTEXITCODE -ne 0) { throw "Explicit vignette rendering failed; inspect vignette-render.log" }

Push-Location $ArtifactDir
try {
  & $rExe CMD build $packageRoot *> (Join-Path $ArtifactDir "build.log")
  if ($LASTEXITCODE -ne 0) { throw "Source build failed; inspect build.log" }
} finally { Pop-Location }

$descriptionPath = Join-Path $packageRoot "DESCRIPTION"
$versionLine = Get-Content -LiteralPath $descriptionPath | Where-Object { $_ -match "^Version:\s*(.+)$" } | Select-Object -First 1
if (!$versionLine) { throw "Could not read package version from DESCRIPTION" }
$version = ($versionLine -replace "^Version:\s*", "").Trim()
$expectedTarball = "BreedReliabR_$version.tar.gz"
$tarball = Get-ChildItem -LiteralPath $ArtifactDir -Filter $expectedTarball -File | Select-Object -First 1
if (!$tarball) { throw "Expected $expectedTarball was not created" }
& $rExe CMD check --as-cran --library="$library" --output="$checkDir" $tarball.FullName *> (Join-Path $ArtifactDir "R-CMD-check.log")
if ($LASTEXITCODE -ne 0) { throw "R CMD check did not finish cleanly; inspect R-CMD-check.log and check directory" }

$checkLogs = Get-ChildItem -LiteralPath $checkDir -Filter "00check.log" -File -Recurse
if ($checkLogs.Count -ne 1) { throw "Expected exactly one 00check.log under $checkDir" }
$statusLines = Get-Content -LiteralPath $checkLogs[0].FullName | Where-Object { $_ -match '^Status:' }
if ($statusLines.Count -ne 1) { throw "Could not identify exactly one final Status line in 00check.log" }
if ($statusLines[0].Trim() -ne 'Status: OK') {
  throw "R CMD check completed with ERROR, WARNING, or NOTE: $($statusLines[0])"
}
Copy-Item -LiteralPath $checkLogs[0].FullName -Destination (Join-Path $ArtifactDir "00check.log") -Force
Set-Content -LiteralPath (Join-Path $ArtifactDir "U12_NATIVE_PASS.txt") -Value @(
  'BreedReliabR 0.1.2 U12 native Windows release gate: PASS',
  'R CMD check --as-cran: Status: OK',
  "Source tarball: $expectedTarball"
)

Write-Output "U12 native release validation PASS. Artifacts are in $ArtifactDir"
