# Karlsruhe weather explorer: a one-file Shiny app
# Run from the project root: shiny::runApp("c04/app")

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, shiny, bslib)

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
    checkboxInput("smooth", "Show trend", value = TRUE)
  ),
  card(plotOutput("trend_plot")),
  card(tableOutput("summary_table"))
)

# ---- Backend ----
server <- function(input, output) {

  # Shared data pipeline: re-computed only when one of its inputs changes
  seasonal <- reactive({
    weather |>
      mutate(year = year(date)) |>
      filter(
        year >= first(input$years),
        year <= last(input$years),
        season %in% input$seasons
      ) |>
      select(year, season, value = all_of(input$measure)) |>
      group_by(year, season) |>
      summarize(value = mean(value, na.rm = TRUE)) |>
      ungroup()
  })

  output$trend_plot <- renderPlot({
    measure_label <- measures |>
      keep(\(m) m == input$measure) |>
      names()

    plot <- seasonal() |>
      ggplot(aes(x = year, y = value, color = season)) +
      geom_line(alpha = 0.5) +
      scale_color_manual(values = season_colors) +
      labs(
        x = NULL,
        y = measure_label,
        color = NULL
      ) +
      theme_minimal(base_size = 14) +
      theme(legend.position = "bottom")

    if (input$smooth)
      plot <- plot + geom_smooth(method = "loess", formula = y ~ x, se = FALSE)

    plot
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
}

shinyApp(ui, server)
