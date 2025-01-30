#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @importFrom plotly plotlyOutput
#' @importFrom stats na.omit na.omit
#' @importFrom shinyWidgets switchInput
#' @importFrom DT DTOutput
#' @noRd
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),
    fluidPage(
      tags$head(
        tags$style(HTML("
          .hover-name {
            position: relative;
            display: inline-block;
          }
          .hover-name .hover-image {
            display: none;
            position: fixed;
            top: 0px;
            left: 0px;
            z-index: 1;
          }
          .hover-name:hover .hover-image {
            display: block;
          }
        "))
      ),
      titlePanel("Danish Vegetation Types"),
      sidebarLayout(
        shiny::sidebarPanel(
          shiny::h5("Would you like to practice only some habitats? Turn on the filter"),
          shinyWidgets::switchInput("HabFilter", "filter"),
          shiny::conditionalPanel(
            condition = "input.HabFilter",
            shiny::selectizeInput(inputId = "HabChoice",
                                  label = "Which habitats would you like to practice with",
                                  choices = sort(as.character(stats::na.omit(unique(FloraExam::SpatialData$MajorHabName)))),
                                  multiple = TRUE)
          ),
          actionButton("update", "Pick random plot",
                       class = "btn-primary", style='padding:4px; font-size:120%'),
          shiny::conditionalPanel(
            condition = "input.update != 0",
            shiny::selectizeInput(inputId = "Answer",
                                  label = shiny::h3("What is this Major habitat type? Choose it in the list"),
                                  choices = c(sort(as.character(stats::na.omit(unique(FloraExam::SpatialData$MajorHabName)))), ""),
                                  multiple = TRUE,
                                  options = list(maxItems = 1)),
            shiny::uiOutput("Question2"),
            shiny::htmlOutput("Rightwrong")
          ),
          shiny::conditionalPanel(
            condition = "input.update != 0",
            shiny::uiOutput("Map")
          )
        ),
        shiny::mainPanel(
          shiny::conditionalPanel(
            condition = "input.update != 0",
            shiny::downloadButton("report", "Generate pdf")),
          shiny::textOutput("Artscore"),
          DT::DTOutput("tbl_myhab"),
          plotly::plotlyOutput("plot_ellenberg"),
          plotly::plotlyOutput("plot_csr", width = "90%", height = "90%")
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )
  add_resource_path(
    "data-raw",
    app_sys("data-raw")
  )
  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "TestExamapp"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
