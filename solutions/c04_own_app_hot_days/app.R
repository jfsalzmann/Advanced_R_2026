# Solution to the c04 Try-it "your own app", first suggestion: hot days per year
# Run from the project root: shiny::runApp("solutions/c04_own_app_hot_days")

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, shiny, bslib)

weather <- read_csv("weather_karlsruhe.csv", show_col_types = FALSE)

# ---- Frontend ----
ui <- page_sidebar(
  title = "How many hot days did each year have?",
  sidebar = sidebar(
    sliderInput(
      "threshold",
      "Maximum temperature at least (°C)",
      min = 25,
      max = 35,
      value = 30,
      step = 5
    ),
    sliderInput(
      "years",
      "Years",
      min = 1876,
      max = 2025,
      value = c(1950, 2025),
      sep = ""
    )
  ),
  card(plotOutput("days_plot"))
)

# ---- Backend ----
server <- function(input, output) {

  output$days_plot <- renderPlot({
    weather |>
      mutate(year = year(date)) |>
      filter(year >= first(input$years), year <= last(input$years)) |>
      group_by(year) |>
      summarize(days = sum(temp_max >= input$threshold, na.rm = TRUE)) |>
      ungroup() |>
      ggplot(aes(x = year, y = days)) +
      geom_col(fill = "#B2182B") +
      labs(
        x = NULL,
        y = str_glue("Days of {input$threshold} °C or more")
      ) +
      theme_minimal(base_size = 14)
  })
}

shinyApp(ui, server)
