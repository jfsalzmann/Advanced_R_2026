# Solution to the c04 Try-it "extend the app": c04/app/app.R with all four suggested features
# Run from the project root: shiny::runApp("solutions/c04_extend_app")

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, shiny, bslib, plotly)

weather <- read_csv("weather_karlsruhe.csv", show_col_types = FALSE)

measures <- c(
  "Mean temperature (°C)" = "temp_mean",
  "Maximum temperature (°C)" = "temp_max",
  "Minimum temperature (°C)" = "temp_min",
  "Precipitation (mm)" = "precip",
  "Sunshine (hours)" = "sunshine"
)

season_colors <- c(
  Winter = "#3B6FB6",
  Spring = "#6AA84F",
  Summer = "#E69138",
  Autumn = "#A64D79"
)

# ---- Frontend ----
ui <- page_sidebar(
  title = "Karlsruhe weather explorer",
  sidebar = sidebar(
    selectInput("measure", "Measure", choices = measures),
    radioButtons(
      "statistic",
      "Per year",
      choices = c("yearly mean", "yearly maximum")
    ),
    sliderInput(
      "years",
      "Years",
      min = 1876,
      max = 2025,
      value = c(1950, 2025),
      sep = ""
    ),
    checkboxGroupInput(
      "seasons",
      "Seasons",
      choices = names(season_colors),
      selected = names(season_colors)
    ),
    checkboxInput("smooth", "Show trend", value = TRUE),
    downloadButton("download_plot", "Download plot (PNG)")
  ),
  card(textOutput("warmest_year")),
  card(plotlyOutput("trend_plot")),
  card(tableOutput("summary_table"))
)

# ---- Backend ----
server <- function(input, output) {

  seasonal <- reactive({
    statistic <- if (input$statistic == "yearly mean")
      mean else
      max

    weather |>
      mutate(year = year(date)) |>
      filter(
        year >= first(input$years),
        year <= last(input$years),
        season %in% input$seasons
      ) |>
      select(year, season, value = all_of(input$measure)) |>
      group_by(year, season) |>
      summarize(value = statistic(value, na.rm = TRUE)) |>
      ungroup()
  })

  # The ggplot is needed twice: for plotly and for the download
  trend_plot <- reactive({
    measure_label <- measures |>
      keep(\(m) m == input$measure) |>
      names()

    plot <- seasonal() |>
      ggplot(aes(x = year, y = value, color = season)) +
      geom_line(alpha = 0.5) +
      scale_color_manual(values = season_colors) +
      labs(
        x = NULL,
        y = str_c(measure_label, ", ", input$statistic),
        color = NULL
      ) +
      theme_minimal(base_size = 14) +
      theme(legend.position = "bottom")

    if (input$smooth)
      plot <- plot + geom_smooth(method = "loess", formula = y ~ x, se = FALSE)

    plot
  })

  output$trend_plot <- renderPlotly({
    trend_plot() |>
      ggplotly()
  })

  output$warmest_year <- renderText({
    warmest <- weather |>
      mutate(year = year(date)) |>
      filter(year >= first(input$years), year <= last(input$years)) |>
      group_by(year) |>
      summarize(temp_mean = mean(temp_mean, na.rm = TRUE)) |>
      ungroup() |>
      slice_max(temp_mean, n = 1)

    str_glue(
      "The warmest year from {first(input$years)} to {last(input$years)}: ",
      "{warmest$year}, with a mean of {round(warmest$temp_mean, 1)} °C."
    )
  })

  output$summary_table <- renderTable({
    seasonal() |>
      group_by(season) |>
      summarize(
        mean = mean(value),
        min = min(value),
        max = max(value)
      )
  })

  output$download_plot <- downloadHandler(
    filename = "karlsruhe_trend.png",
    content = function(file) {
      ggsave(file, trend_plot(), width = 10, height = 6, dpi = 150, bg = "white")
    }
  )
}

shinyApp(ui, server)
