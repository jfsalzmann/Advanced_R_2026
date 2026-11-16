# ============================================================
# C04 · SHINY APPS -- CLASSROOM QUICK-REFERENCE
# ============================================================
# The complete app: c04/app/app.R (one file) and c04/app_two_files/ (global.R, ui.R, server.R)


# ============================================================
# 1. PACKAGES ----
# ============================================================

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, shiny, bslib)


# ============================================================
# 2. BASIC STRUCTURE ----
# ============================================================
# UI (frontend) + server function (backend) + shinyApp() to connect them

ui <- page_fluid(
  sliderInput("n", "Number of days", min = 10, max = 1000, value = 100),
  plotOutput("histogram")
)

server <- function(input, output) {
  output$histogram <- renderPlot({
    tibble(temp = rnorm(input$n, mean = 10, sd = 8)) |>
      ggplot(aes(x = temp)) +
      geom_histogram(bins = 30)
  })
}

shinyApp(ui, server)

# One file (app.R) or two (ui.R + server.R, plus global.R): both run the same way
runApp("c04/app")
runApp("c04/app_two_files")


# ============================================================
# 3. FRONTEND: INPUTS, OUTPUTS, LAYOUT ----
# ============================================================
# every input: an ID (input$ID in the server), a label, the choices or range

selectInput("measure", "Measure", choices = c("Mean" = "temp_mean", "Max" = "temp_max"))
sliderInput("years", "Years", min = 1876, max = 2025, value = c(1950, 2025), sep = "")
checkboxGroupInput("seasons", "Seasons", choices = c("Winter", "Spring", "Summer", "Autumn"))
checkboxInput("smooth", "Show trend", value = TRUE)
dateRangeInput("dates", "Period", start = "2025-01-01", end = "2025-12-31")

# outputs: plotOutput(), tableOutput(), textOutput(), plotlyOutput()
# layout with bslib: a sidebar for the controls, cards for the outputs

measures <- c(
  "Mean temperature (°C)" = "temp_mean",
  "Maximum temperature (°C)" = "temp_max"
)

ui <- page_sidebar(
  title = "Karlsruhe weather explorer",
  sidebar = sidebar(
    selectInput("measure", "Measure", choices = measures),
    sliderInput("years", "Years", min = 1876, max = 2025, value = c(1950, 2025), sep = "")
  ),
  card(plotOutput("trend_plot")),
  card(tableOutput("summary_table"))
)


# ============================================================
# 4. BACKEND: REACTIVITY ----
# ============================================================
# server code: only valid inside server <- function(input, output) { ... }, see c04/app/app.R
# each render*() re-runs whenever an input$... it uses changes, and only then

# output$trend_plot <- renderPlot({
#   weather |>
#     filter(year(date) >= first(input$years), year(date) <= last(input$years)) |>
#     ggplot(aes(x = date, y = temp_mean)) +
#     geom_line()
# })

# reactive(): one shared data pipeline, called like a function, with ()

# seasonal <- reactive({
#   weather |>
#     mutate(year = year(date)) |>
#     filter(
#       year >= first(input$years),
#       year <= last(input$years),
#       season %in% input$seasons
#     ) |>
#     select(year, season, value = all_of(input$measure)) |>
#     group_by(year, season) |>
#     summarize(value = mean(value, na.rm = TRUE), .groups = "drop")
# })
#
# output$trend_plot <- renderPlot({
#   seasonal() |>
#     ggplot(aes(x = year, y = value, color = season)) +
#     geom_line()
# })
#
# output$summary_table <- renderTable({
#   seasonal() |>
#     group_by(season) |>
#     summarize(mean = mean(value))
# })


# ============================================================
# 5. DEPLOYING AN APP ----
# ============================================================
# Posit Connect Cloud / shinyapps.io: everything the app reads must live inside its folder
# Shinylive: runs in the browser, static hosting; own server: Shiny Server, Docker

rsconnect::deployApp("c04/app")


# ============================================================
# 6. TRY IT: EXTEND THE APP ----
# ============================================================

# Your task: add one feature to c04/app/app.R, for example:
# - a radioButtons() input to choose between "yearly mean" and "yearly maximum",
# - a textOutput() stating the warmest year in the selected period,
# - the plot as an interactive plotlyOutput() / renderPlotly() with ggplotly(),
# - a downloadButton() that saves the current plot as PNG.


# ============================================================
# 7. TRY IT: YOUR OWN APP ----
# ============================================================

# Your task: build a new one-file app for a question of your choice, e.g. "How many hot days
# did each year have?" with a bar chart and a slider for the threshold temperature (25, 30
# or 35 °C), or the warming stripes from c02 with a selectable reference period.
