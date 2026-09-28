# Stage H validation records

`stage_h_validation_report.md` and `stage_h_python_validation.csv` preserve the historical Python-based validation performed before native R was available. Their statements about the absent R runtime describe that earlier environment.

Stage H2 subsequently ran the native R suite on Windows with R 4.6.1 and testthat 3.3.2: all 15 tests and 29 expectations passed without skips. Final native installation, build, and check evidence is retained in the local `.h2/` validation directory, excluded from the source tarball. See the package README for rerun instructions.
