# ui.R: the frontend, its last value is the UI
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

ui
