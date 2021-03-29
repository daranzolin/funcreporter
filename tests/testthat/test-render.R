library(funcreporter)

output_file <- "testthat_render.html"
test_that("funcreporter renders Rmd", {
  set_funcreporter_pkg("funcreporter")
  funcreporter(
    "Sample Template",
    params = list(species = "setosa"),
    output_file = output_file
  )
  setwd(here::here())
  expect_true(file.exists(output_file))
})
file.remove(output_file)
