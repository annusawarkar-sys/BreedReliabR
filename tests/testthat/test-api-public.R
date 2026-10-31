test_that("the frozen seven-function scientific core and diagnostic preflight remain registered", {
  expect_setequal(getNamespaceExports("BreedReliabR"), c(
    "br_prediction", "br_tpe", "br_omega", "br_advance",
    "br_compare", "br_curve", "br_support", "br_check_inputs"
  ))
  expect_true(is.function(getS3method("print", "br_prediction")))
  expect_true(is.function(getS3method("print", "br_tpe")))
  expect_true(is.function(getS3method("print", "br_omega")))
  expect_true(is.function(getS3method("print", "br_advancement")))
  expect_true(is.function(getS3method("summary", "br_comparison")))
  expect_true(is.function(getS3method("plot", "br_curve")))
  expect_true(is.function(getS3method("plot", "br_support")))
  expect_true(is.function(getS3method("print", "br_input_check")))
})
