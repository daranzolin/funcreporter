#' Print YAML report descriptions to the console
#'
#' @export
#'
#' @examples
#'\dontrun{
#' print_report_descriptions()
#' }
print_report_descriptions <- function() {
  yaml_files <- yaml_files()
  n_templates <- length(yaml_files)
  message(glue::glue("Showing names and descriptions of {n_templates} templates in the {Sys.getenv('FUNCREPORTER_PKG')} package..."))
  cat("---------------------------------", "\n")
  for (i in seq_along(yaml_files)) {
    yf <- yaml_files[i]
    s <- fs::path(dirname(yf), "skeleton/skeleton.Rmd")
    y <- yaml::read_yaml(yaml_files[i])
    param_info <- rmarkdown::yaml_front_matter(s)$params
    cat("Name: ", y$name, "\n")
    cat("Description: ", y$description, ifelse(grepl("\n$", y$description), "", "\n"))
    cat("Create dir: ", ifelse(y$create_dir, y$create_dir, FALSE), "\n")
    print_param_info(param_info)
    cat("---------------------------------", "\n")

  }
}

#' Set funcreporter env vars
#'
#' @param pkg_name Name of package with templates
#'
#' @export
#'
#' @examples
#' \dontrun{
#' set_funcreporter_pkg("reporting_pacakge")
#' }
set_funcreporter_pkg <- function(pkg_name) {
  Sys.setenv(FUNCREPORTER_PKG = pkg_name)
  message(glue::glue("Setting env var FUNCREPORTER_PKG={pkg_name}"))
  path_to_template <- file.path(.libPaths(), pkg_name, "rmarkdown", "templates")
  if (length(path_to_template) > 1) {
    path_to_template <- path_to_template[1]
  }
  Sys.setenv(FUNCREPORTER_PATH_TO_TEMPLATES = path_to_template)
  message(glue::glue("Setting env var FUNCREPORTER_PATH_TO_TEMPLATES={path_to_template}"))
}

yaml_files <- function() {
  template_files <- dir(Sys.getenv("FUNCREPORTER_PATH_TO_TEMPLATES"), full.names = TRUE, recursive = TRUE)
  out <- template_files[grepl("template.yaml$", template_files)]
  out
}

report_lookup_vector <- function() {
  yf <- yaml_files()
  template_names <- vector(mode = "character", length = length(yf))
  template_dirs <- basename(fs::path_dir(yf))
  for (i in seq_along(yf)) {
    y <- yaml::read_yaml(yf[i])
    template_names[i] <- y$name
  }
  names(template_dirs) <- template_names
  template_dirs
}

print_param_info <- function(x) {
  cat("Params:", "\n")
  for (i in seq_along(x)) {
    cat(i, ". ", names(x[i]), "\n", sep = "")
    param <- x[[i]]
    if (!is.null(param$label)) cat("\t", "Label:", param$label, "\n")
    if (!is.null(param$value)) cat("\t", "Value:", param$value, "\n")
    if (!is.null(param$choices)) {
      cat("\t", "Choices:", "\n")
      for (choice in param$choices) {
        cat("\t\t", "*", choice, "\n")
      }
    }
  }
}
