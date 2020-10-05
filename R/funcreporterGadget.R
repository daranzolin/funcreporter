#' GUI to Run Parameterized Reports
#'
#' @importFrom shiny uiOutput renderUI observeEvent
#' @export
funcreporterGadget <- function() {

  pkg_check <- Sys.getenv("FUNCREPORTER_PKG")

  if (pkg_check == "") stop("Please set your reporting package with set_funcreporter_pkg()", call. = FALSE)

  lookup_v <- report_lookup_vector()
  param_names <- ""

  ui <- miniUI::miniPage(
    miniUI::gadgetTitleBar("funcreporter Gadget", right = NULL),
    miniUI::miniContentPanel(
      shiny::selectInput("template", "Select Template:",
                         choices = lookup_v),
      shiny::actionButton("templateConfirm",
                          "Confirm Template",
                          icon = shiny::icon("check-circle"),
                          style = "color: #fff; background-color: #337ab7; border-color: #2e6da4"),
      uiOutput("templateParams"),
      uiOutput("outputFormatInput"),
      uiOutput("reportNameInput"),
      uiOutput("keepRmd"),
      uiOutput("runReport")
    )
  )

  server <- function(input, output, session) {

    observeEvent(input$templateConfirm, {
      template_path <- lookup_v[which(lookup_v == input$template)]
      skeleton <- grep("skeleton.Rmd$",
                       dir(file.path(Sys.getenv("FUNCREPORTER_PATH_TO_TEMPLATES"), template_path, "skeleton"),
                           full.names = TRUE),
                       value = TRUE)
      tp <- packagedocs::read_rmd_yaml(skeleton)$params
      param_names <<- names(tp)
      if (!is.null(tp)) {
        output$templateParams <- renderUI({
          uiParams <- vector(mode = "list", length = length(tp))
          for (i in seq_along(tp)) {
            tpx <- tp[[i]]
            if (tpx$input == "select") {
              uiParams[[i]] <- shiny::selectInput(param_names[i],
                                                  label = tpx$label,
                                                  choices = tpx$choices,
                                                  multiple = ifelse(is.null(tpx$multiple), FALSE, tpx$multiple),
                                                  selected = tpx$value)
            } else if (tpx$input == "text") {
              uiParams[[i]] <- shiny::textInput(param_names[i],
                                                label = tpx$label,
                                                value = tpx$value)
            } else if (tpx$input == "numeric") {
              uiParams[[i]] <- shiny::numericInput(param_names[i],
                                                   label = tpx$label,
                                                   value = tpx$value)
            } else if (tpx$input == "date") {
              uiParams[[i]] <- shiny::dateInput(param_names[i],
                                                label = tpx$label,
                                                value = tpx$value)
            }
          }
          do.call(shiny::tagList, uiParams)
        })
      } else {
        output$templateParams <- shiny::renderText("\n")
      }

      output$outputFormatInput <- renderUI({
        shiny::selectInput("outputFormat", "Output Format:", choices = list("html_document", "pdf_document", "word_document"))
      })

      output$reportNameInput <- renderUI({
        shiny::textInput("reportName", "File Name: ")
      })

      output$keepRmd <- renderUI({
        shiny::checkboxInput("keepRmdBox", "Keep report files?", value = FALSE)
      })

      output$runReport <- renderUI({
        shiny::actionButton("report",
                            "Run Report",
                            icon = shiny::icon("clipboard-list"),
                            style = "color: #fff; background-color: #ce3c23; border-color: #2e6da4")
      })
    })

    observeEvent(input$report, {

      rv <- shiny::reactiveValuesToList(input)
      params <- rv[param_names]
      rtf <- input$keepRmdBox
      report_name <- input$reportName
      rtf <- ifelse(rtf, FALSE, TRUE)
      funcreporter::funcreporter(
        template_name = input$template,
        output_format = input$outputFormat,
        output_file = report_name,
        params = params,
        remove_copied_template_files = rtf
        )
    })
  }
  shiny::runGadget(ui, server)
}
