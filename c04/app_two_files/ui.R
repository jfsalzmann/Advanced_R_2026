# ui.R: the frontend (two tabs with a sidebar each), its last value is the UI
ui <- page_navbar(
  title = "Karlsruhe weather explorer",
  nav_panel(
    "Seasonal trends",
    layout_sidebar(
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
      card(plotlyOutput("trend_plot")),
      card(tableOutput("summary_table"))
    )
  ),
  nav_panel(
    "Warming stripes",
    layout_sidebar(
      sidebar = sidebar(
        sliderInput(
          "reference",
          "Reference period",
          min = 1876,
          max = 2025,
          value = c(1961, 1990),
          sep = ""
        ),
        sliderInput(
          "stripe_years",
          "Years shown",
          min = 1876,
          max = 2025,
          value = c(1876, 2025),
          sep = ""
        )
      ),
      card(plotOutput("stripes_plot"))
    )
  )
)

ui
