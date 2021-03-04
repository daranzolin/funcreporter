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
                         params = NULL,
                         remove_copied_template_files = TRUE,
                         envir = new.env(),
                         ...) {

  no_params <- is.null(params)
  if (!no_params) {
    params <- harmonize_params_list_lengths(params)
  }

  if (!no_params & length(params) != length(output_file)) {
    stop("Length of params and output_files must match.", call. = FALSE)
  }

  lookup_v <- report_lookup_vector()
  tn <- lookup_v[template_name]
  stopifnot(names(tn) %in% existing_templates())
  report_dir <- template_path(tn)
  output_dir <- here::here()
  copied_files <- copy_skeleton_files(tn, output_dir)
  if (remove_copied_template_files) {
    on.exit(for (i in seq_along(copied_files)) file.remove(copied_files[i]))
  }
  input <- file.path(report_dir, "skeleton.Rmd")
  if (no_params) {
    rmarkdown::render(
      input = input,
      output_file = output_file,
      output_format = output_format,
      envir = envir,
      output_dir = output_dir,
      ...
    )
  } else {
    purrr::walk2(output_file,
                 params,
                 ~rmarkdown::render(input = input,
                                    output_format = output_format,
                                    output_file = .x,
                                    params = .y,
                                    envir = envir,
                                    ...)
    )

    # Look, I dont like it either
    output_pat <- paste(output_file, collapse = "|")
    output_report_dirs <- dir(pattern = output_pat)
    output_report_files <- dir(pattern = output_pat,
                               full.names = TRUE,
                               recursive = TRUE)
    purrr::walk(output_report_files, ~fs::file_copy(.x, output_dir))
    purrr::walk(output_report_dirs, fs::dir_delete)
  }
}

template_path <- function(template_name) {
  file.path(Sys.getenv("FUNCREPORTER_PATH_TO_TEMPLATES"), template_name, "skeleton")
}

existing_templates <- function() {
  yf <- yaml_files()
  template_names <- vector(mode = "character", length = length(yf))
  for (i in seq_along(yf)) {
    y <- yaml::read_yaml(yf[i])
    template_names[i] <- y$name
  }
  template_names
}

copy_skeleton_files <- function(template_name, path_to) {
  template_files <- dir(template_path(template_name), full.names = TRUE)
  new_files <- file.path(path_to, basename(template_files))
  purrr::walk2(template_files, new_files, ~{
    if (!file.exists(.y)) file.copy(.x, .y)
  })
  return(new_files)
}

harmonize_params_list_lengths <- function(x) {
  stopifnot(inherits(x, "list"))
  max_length <- max(sapply(x, function(x) length(x)))
  for (i in seq_along(x)) {
    if (is.factor(x[[i]])) {
      x[[i]] <- as.character(x[[i]])
    }
    len <- length(x[[i]])
    if (!len %in% c(1, max_length)) {
      em <- paste("params must be either length 1 or", max_length)
      stop(em, call. = FALSE)
    }
    if (len == 1) {
      x[[i]] <- rep(x[[i]], max_length)
    }
  }
  purrr::transpose(x)
}
