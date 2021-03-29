library(funcreporter)

test_that("funcreporter renders Rmd", {
  output_file <-"testthat-render.html"
  on.exit(unlink(output_file))
  set_funcreporter_pkg("funcreporter")
  funcreporter(
    "Sample Template",
    params = list(species = "setosa"),
    output_file = output_file
  )
  setwd(here::here())
  expect_true(file.exists(output_file))
})
