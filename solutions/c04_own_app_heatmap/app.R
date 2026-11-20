# Solution to the c04 Try-it "your own app", second suggestion: a heatmap of monthly means
# Run from the project root: shiny::runApp("solutions/c04_own_app_heatmap")

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, shiny, bslib)

weather <- read_csv("weather_karlsruhe.csv", show_col_types = FALSE)

measures <- c(
  "Mean temperature (°C)" = "temp_mean",
  "Maximum temperature (°C)" = "temp_max",
  "Minimum temperature (°C)" = "temp_min",
  "Precipitation (mm per day)" = "precip",
  "Sunshine (hours per day)" = "sunshine"
)

# ---- Frontend ----
ui <- page_sidebar(
  title = "Monthly means in Karlsruhe",
  sidebar = sidebar(
    selectInput("measure", "Measure", choices = measures),
    sliderInput(
      "years",
      "Years",
      min = 1876,
      max = 2025,
      value = c(1950, 2025),
      sep = ""
    )
  ),
  card(plotOutput("heatmap"))
)

# ---- Backend ----
server <- function(input, output) {

  output$heatmap <- renderPlot({
    measure_label <- measures |>
      keep(\(m) m == input$measure) |>
      names()

    weather |>
      mutate(year = year(date)) |>
      filter(year >= first(input$years), year <= last(input$years)) |>
      select(year, month, value = all_of(input$measure)) |>
      group_by(year, month) |>
      summarize(value = mean(value, na.rm = TRUE)) |>
      ungroup() |>
      ggplot(aes(x = year, y = factor(month, labels = month.abb), fill = value)) +
      geom_tile() +
      scale_fill_viridis_c(option = "inferno", na.value = "grey90") +
      labs(
        x = NULL,
        y = NULL,
        fill = measure_label
      ) +
      theme_minimal(base_size = 14) +
      theme(legend.position = "bottom")
  })
}

shinyApp(ui, server)
