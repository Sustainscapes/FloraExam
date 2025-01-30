#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @importFrom Artscore Artscore
#' @importFrom dplyr filter slice_sample left_join select mutate starts_with mutate_if group_by summarise distinct
#' @importFrom stringr str_remove_all str_to_sentence str_replace_all
#' @importFrom tidyr pivot_longer everything
#' @importFrom rlang sym
#' @importFrom stats median
#' @importFrom plotly renderPlotly ggplotly plot_ly add_trace layout
#' @importFrom ggplot2 ggplot theme_bw geom_boxplot coord_flip ylim xlab aes
#' @importFrom ggrepel geom_text_repel
#' @importFrom leaflet renderLeaflet leaflet addCircles addProviderTiles leafletOutput
#' @importFrom rmarkdown render
#' @importFrom DT datatable formatStyle styleEqual renderDT
#' @noRd
#'

resetForm<-function(session){
  updateSelectInput(session, "Answer",selected = "")
}

app_server <- function(input, output, session) {
  Median <- MajorHabName <- habitat_name <- NavnDansk <- value <- Ellenberg <- canonicalName <- species <- rank <- C <- R <- S <- characteristic <- NULL

  # Initialize object to store reactive values

  rvs <- reactiveValues(Artscore = NULL,
                        SpeciesList = NULL,
                        Histogram = NULL,
                        Ternary = NULL,
                        Dataset = NULL)

  # Your application server logic
  my_habitatdata <- eventReactive(input$update, {
    resetForm(session)
    if(input$HabFilter){
      FloraExam::SpatialData |>
        dplyr::filter(MajorHabName %in% input$HabChoice) |>
        dplyr::slice_sample(n = 1) |>
        dplyr::left_join(FloraExam::Final_Frequency) |>
        dplyr::left_join(FloraExam::Ellenberg_CSR) |>
        dplyr::left_join(FloraExam::Characteristic_Species) |>
        dplyr::distinct()
    } else {
      FloraExam::SpatialData |>
        dplyr::slice_sample(n = 1) |>
        dplyr::left_join(FloraExam::Final_Frequency) |>
        dplyr::left_join(FloraExam::Ellenberg_CSR) |>
        dplyr::left_join(FloraExam::Characteristic_Species) |>
        dplyr::distinct()
    }
    })

  output$Artscore <- renderText({
    req(nrow(my_habitatdata()) > 0)  # Check if my_habitatdata() has at least 1 row

    tryCatch({
      Index <- Artscore::Artscore(ScientificName = my_habitatdata()$species, Habitat_code = unique(my_habitatdata()$habtype))$Artsindex
      rvs$Artscore <- paste("The artsindex for this site is", round(Index, 3), "and the number of species in this plot is", length(unique(my_habitatdata()$species)))
      rvs$Artscore
    }, error = function(e) {
      rvs$Artscore <- "Artscore cannot be calculated for this habitat."
      rvs$Artscore
    })
  })



  # output$Test <- shiny::renderText({
  #   my_habitatdata()$MajorHabName[1]
  # })
  output$Rightwrong <- shiny::renderUI({
    if (req(input$Answer2) == my_habitatdata()$habitat_name[1]) {
      shiny::HTML(paste("<h2>You are correct! the precise habitat type was", my_habitatdata()$habitat_name[1], ". Try another plot by clicking on the <em>Pick random plot</em> button<h2>"))
    } else if (req(input$Answer2) != my_habitatdata()$habitat_name[1]) {
      shiny::HTML("<h2>Try again!<h2>")
    }
  })

  output$Question2 <- renderUI({
    if (req(input$Answer) == my_habitatdata()$MajorHabName[1]) {
    shiny::selectizeInput(inputId = "Answer2",
                          label = shiny::h3("You are correct!!, What is the specific habitat type? Choose it in the list"),
                          choices = c(sort((dplyr::filter(FloraExam::SpatialData, MajorHabName == my_habitatdata()$MajorHabName[1]))$habitat_name), ""),
                          multiple = TRUE,
                          options = list(maxItems = 1))
    } else if (req(input$Answer) != my_habitatdata()$MajorHabName[1]) {
      shiny::HTML("<h2>Try again!<h2>")
    }
    })

  output$Leaflet <- leaflet::renderLeaflet({
    if (req(input$Answer2) == my_habitatdata()$habitat_name[1]) {
      leaflet::leaflet(data = my_habitatdata()) |>
        leaflet::addProviderTiles("Esri.WorldImagery") |>
        leaflet::addCircles(lng = ~Long, lat = ~Lat)
    }
  })


  output$Map <- renderUI({
    if (req(input$Answer) == my_habitatdata()$MajorHabName[1]) {
      leaflet::leafletOutput("Leaflet")
    }
  })

  # output$major_hint <- shiny::renderText({
  #   if(req(input$Hint)){
  #     paste("The habitat type is within the", my_habitatdata()$MajorHabName[1],"major habitat")
  #   }
  # })

  output$plot_ellenberg <- plotly::renderPlotly({
    Medians <- my_habitatdata() |>
      dplyr::select(light, temperature, moisture, reaction, nutrients, salinity) |>
      tidyr::pivot_longer(tidyr::everything(), names_to = "Ellenberg") |>
      dplyr::group_by(Ellenberg) |>
      dplyr::summarise(Median = median(value, na.rm = T))

    G <- my_habitatdata() |>
      dplyr::select(light, temperature, moisture, reaction, nutrients, salinity) |>
      tidyr::pivot_longer(tidyr::everything(), names_to = "Ellenberg") |>
      ggplot2::ggplot(ggplot2::aes(x = Ellenberg, y = value)) + ggplot2::geom_boxplot() +
      ggplot2::coord_flip() + ggplot2::theme_bw() + ylim(c(0,10)) + ggplot2::xlab("Ecological indicator value") + ggplot2::xlab("Ecological indicator value") + ggrepel::geom_text_repel(data = Medians, aes(x = Ellenberg, y = Median, label = round(Median, 2)))
    rvs$Histogram <- G
    plotly::ggplotly(G)
  })
  output$plot_csr <- plotly::renderPlotly({

    rvs$Dataset <- my_habitatdata() |>
      dplyr::select(C, R, S) |>
      dplyr::filter(!is.na(C))

    message(nrow(rvs$Dataset))

    Tern <- plotly::plot_ly(my_habitatdata()) |>
      plotly::add_trace(
        type = 'scatterternary',
        mode = 'markers',
        a = ~C,
        b = ~R,
        c = ~S,
        text = ~Label,
        marker = list(
          symbol = "100",
          color = my_habitatdata()$RGB,
          size = 5,
          line = list('width' = 2)
        ))  |>  plotly::layout(
          title = "",
          ternary = list(
            sum = 100,
            aaxis = list(
              title = "Competitor"
            ),
            baxis = list(
              title = "Ruderal"
            ),
            caxis = list(
              title = "Stress tolerator"
            )
          ))

    Tern
    rvs$Ternary <- Tern

  })

  output$tbl_myhab <- DT::renderDT({
    Table <- my_habitatdata() |>
      dplyr::select(NavnDansk,
                    Taxa,
                    light, temperature, moisture, reaction, nutrients, salinity, C, S , R, characteristic, taxon_id_Arter, photo_file) |>
      dplyr::mutate_if(is.numeric, round) |>
      dplyr::distinct()

    rvs$SpeciesList <- Table
    Table  |>
      dplyr::mutate(NavnDansk = paste0('<div class="hover-name"><a href="https://arter.dk/taxa/taxon/details/', taxon_id_Arter,
                                       '" target="_blank">', NavnDansk,
                                       '<div class="hover-image"><img src="', 'Pictures/', photo_file,
                                       '" width="475px"></div></div>')) |>
      dplyr::distinct() |>
      DT::datatable(options = list(lengthMenu = list(c(50, -1), c('50', 'All')),
                                   columnDefs = list(
                                     list(visible = FALSE, targets = c(13, 14)))  # Indices of taxon_id_Arter and photo_file
                                     ), escape = FALSE) %>%
      DT::formatStyle(
        'characteristic',
        target = 'row',
        backgroundColor = DT::styleEqual(c(NA, "I", "C"), c('white', '#a6d96a', '#fdae61'))
      )
  })
  output$report <- downloadHandler(
    filename = paste0("Exam_Test", format(Sys.time(), "%Y-%m-%d"), ".pdf"),
    content = function(file) {
      shiny::withProgress(message = 'Preparing the report',
                   detail = NULL,
                   value = 0, {
                     shiny::incProgress(amount = 0.1, message = 'Recovering all data')

                     tempReport <- file.path(tempdir(), "report.Rmd")
                     file.copy(from = system.file("rmarkdown/templates/mock_exam/skeleton/skeleton.Rmd", package="FloraExam"), to = tempReport, overwrite = TRUE)

                     # Set up parameters to pass to Rmd document
                     params <- list(
                       Artscore = rvs$Artscore,
                       SpeciesList = rvs$SpeciesList,
                       Histogram = rvs$Histogram,
                       Ternary = rvs$Ternary,
                       Dataset = rvs$Dataset
                     )

                     shiny::incProgress(amount = 0.3, message = 'Printing the pdf')
                     rmarkdown::render(tempReport, output_file = file,
                                       params = params,
                                       envir = new.env(parent = globalenv()))
                   })
    }
  )

}

