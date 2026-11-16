# server.R: the backend, its last value is the server function
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
      summarize(value = mean(value, na.rm = TRUE), .groups = "drop")
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

server
