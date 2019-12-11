#' Generate a parameterized report from template
#'
#' @param template_name Template name from package.
#' @param output_format The R Markdown output format to convert to, e.g. "html_document", "pdf_document".
#' @param output_file The name of the output file. Non-existent directories will be created recursively.
#' @param params A list of named parameters.
#' @param remove_copied_template_files An option to remove copied template files after rendering.
#' @param envir The environment in which the code chunks are to be evaluated during knitting.
#' @param ... Other options forwarded to rmarkdown::render
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(funcreporter)
#' set_funcreporter_pkg("funcreporter")
#' funcreporter(
#'     template_name = "Sample Template",
#'     output_format = "html_document",
#'     output_file = "versicolor-report",
#'     params = list(species = "versicolor"))
#' }
funcreporter <- function(template_name,
                         output_format = "html_document",
                         output_file,
                         params,
                         remove_copied_template_files = TRUE,
                         envir = new.env(),
                         ...) {

  lookup_v <- report_lookup_vector()
  tn <- lookup_v[template_name]
  stopifnot(tn %in% existing_templates())
  outdir <- fs::path_dir(output_file)
  if (!outdir == ".") {
    if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
    path_to <- file.path(here::here(), outdir)
  } else {
    path_to <- here::here()
  }
  copied_files <- copy_skeleton_files(tn, path_to)
  input <- file.path(path_to, "skeleton.Rmd")
  output_file <- file.path(path_to, output_file)
  rmarkdown::render(
    input = input,
    output_format = output_format,
    output_file = output_file,
    params = params,
    envir = envir
    )
  if (remove_copied_template_files) {
    on.exit(for (i in seq_along(copied_files)) file.remove(copied_files[i]))
  }
  # if (view) {
    # fs::file_show(output_file)
  #   if (output_format == "html_document") utils::browseURL(output_file)
  #   else system(paste0('open "', output_file, '"'))
  # }
}

template_path <- function(template_name) {
  file.path(Sys.getenv("FUNCREPORTER_PATH_TO_TEMPLATES"), template_name, "skeleton")
}
existing_templates <- function() {
  dir(Sys.getenv("FUNCREPORTER_PATH_TO_TEMPLATES"))
}

copy_skeleton_files <- function(template_name, path_to) {
  template_files <- dir(template_path(template_name), full.names = TRUE)
  new_files <- file.path(path_to, basename(template_files))
  purrr::walk2(template_files, new_files, ~{
    if (!file.exists(.y)) file.copy(.x, .y)
  })
  return(new_files)
}
