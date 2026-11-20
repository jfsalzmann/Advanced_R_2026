# ============================================================
# C02 · ADVANCED VISUALIZATION WITH GGPLOT2 -- CLASSROOM QUICK-REFERENCE
# ============================================================


# ============================================================
# 1. PACKAGES AND DATA ----
# ============================================================
# the cleaned data from c01, aggregated to one row per year

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, scales, patchwork, plotly)

weather <- read_csv("data/weather_karlsruhe.csv")
weather

yearly <- weather |>
  mutate(year = year(date)) |>
  group_by(year) |>
  summarize(
    temp_mean = mean(temp_mean, na.rm = TRUE),
    precip = sum(precip, na.rm = TRUE),
    sunshine = sum(sunshine, na.rm = TRUE),
    hot_days = sum(temp_max >= 30, na.rm = TRUE),
    n_days = n()
  ) |>
  filter(n_days >= 360)
yearly


# ============================================================
# 2. THE GRAMMAR OF GRAPHICS ----
# ============================================================
# data + aesthetics (aes) + geoms, built up layer by layer with +

yearly |>
  ggplot(aes(x = year, y = temp_mean))


# ============================================================
# 3. STANDARD PLOT TYPES ----
# ============================================================
# one geom per question: relation, development, amounts, distribution

# Scatter plot ----

yearly |>
  ggplot(aes(x = year, y = temp_mean)) +
  geom_point()

# Line plot, and lines with points ----

yearly |>
  ggplot(aes(x = year, y = temp_mean)) +
  geom_line(color = "grey60") +
  geom_point()

yearly |>
  ggplot(aes(x = year, y = temp_mean)) +
  geom_line(color = "grey60") +
  geom_point() +
  geom_smooth(method = "loess", formula = y ~ x)

# Bar plot ----

yearly |>
  filter(year >= 2000) |>
  ggplot(aes(x = year, y = hot_days)) +
  geom_col()

# Histogram and density ----

weather |>
  ggplot(aes(x = temp_max)) +
  geom_histogram(binwidth = 1)

weather |>
  ggplot(aes(x = temp_max)) +
  geom_density(fill = "grey80")

# Boxplot ----

weather |>
  ggplot(aes(x = factor(month), y = temp_max)) +
  geom_boxplot()


# ============================================================
# 4. GROUPS AND COLOURS ----
# ============================================================
# mapping a column to color splits the data into groups and adds a legend

seasonal <- weather |>
  mutate(year = year(date)) |>
  filter(year >= 1900, year <= 2025) |>
  group_by(year, season) |>
  summarize(temp_mean = mean(temp_mean, na.rm = TRUE)) |>
  ungroup()

seasonal |>
  ggplot(aes(x = year, y = temp_mean, color = season)) +
  geom_line()

season_order <- c("Winter", "Spring", "Summer", "Autumn")

seasonal <- seasonal |>
  mutate(season = fct_relevel(season, season_order))


# ============================================================
# 5. FACETS ----
# ============================================================
# one small panel per group, same axes

seasonal |>
  ggplot(aes(x = year, y = temp_mean)) +
  geom_line(color = "grey60") +
  geom_smooth(method = "loess", formula = y ~ x) +
  facet_wrap(~ season)

seasonal |>
  ggplot(aes(x = year, y = temp_mean)) +
  geom_line(color = "grey60") +
  geom_smooth(method = "loess", formula = y ~ x) +
  facet_wrap(~ season, scales = "free_y")


# ============================================================
# 6. SCALES AND LABELS ----
# ============================================================
# scale_*() controls how values become colours, positions and labels

# Manual colours ----

season_colors <- c(
  Winter = "#3B6FB6",
  Spring = "#6AA84F",
  Summer = "#E69138",
  Autumn = "#A64D79"
)

seasonal |>
  ggplot(aes(x = year, y = temp_mean, color = season)) +
  geom_line(alpha = 0.4) +
  geom_smooth(method = "loess", formula = y ~ x, se = FALSE) +
  scale_color_manual(values = season_colors)

# Continuous colour scales ----

reference_period <- 1961:1990

reference_temp <- yearly |>
  filter(year %in% reference_period) |>
  summarize(reference = mean(temp_mean)) |>
  pull(reference)

yearly <- yearly |>
  mutate(anomaly = temp_mean - reference_temp)

yearly |>
  ggplot(aes(x = year, y = anomaly, fill = anomaly)) +
  geom_col() +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B")

# Axis labels with the scales package ----

yearly |>
  ggplot(aes(x = year, y = anomaly, fill = anomaly)) +
  geom_col() +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", guide = "none") +
  scale_y_continuous(labels = label_number(suffix = " °C", style_positive = "plus")) +
  scale_x_continuous(breaks = breaks_width(20)) +
  labs(
    title = "Karlsruhe is getting warmer",
    subtitle = "Annual mean temperature vs. 1961-1990 average",
    x = NULL,
    y = "Deviation",
    caption = "Data: Deutscher Wetterdienst"
  )


# ============================================================
# 7. THEMES ----
# ============================================================
# everything that isn't data: fonts, grid lines, legend position

anomaly_plot <- yearly |>
  ggplot(aes(x = year, y = anomaly, fill = anomaly)) +
  geom_col() +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", guide = "none") +
  labs(
    title = "Karlsruhe is getting warmer",
    x = NULL,
    y = "Deviation (°C)"
  )

anomaly_plot + theme_minimal()

theme_report <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.title.position = "plot",
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

anomaly_plot + theme_report()

# Showcase: warming stripes ----

yearly |>
  ggplot(aes(x = year, y = 1, fill = anomaly)) +
  geom_tile() +
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#B2182B", guide = "none") +
  theme_void()


# ============================================================
# 8. MULTIPLE PLOTS WITH PATCHWORK ----
# ============================================================
# + side by side, / on top of each other, & applies to all

temp_plot <- yearly |>
  ggplot(aes(x = year, y = temp_mean)) +
  geom_line() +
  labs(
    title = "Mean temperature",
    x = NULL,
    y = "°C"
  )

hot_plot <- yearly |>
  ggplot(aes(x = year, y = hot_days)) +
  geom_col() +
  labs(
    title = "Days of 30 °C or more",
    x = NULL,
    y = "Days"
  )

precip_plot <- yearly |>
  ggplot(aes(x = year, y = precip)) +
  geom_line() +
  labs(
    title = "Precipitation",
    x = NULL,
    y = "mm"
  )

(temp_plot + hot_plot) / precip_plot +
  plot_annotation(tag_levels = "A") &
  theme_report()


# ============================================================
# 9. SAVING PLOTS ----
# ============================================================
# size in inches, dpi for raster formats

ggsave("c02/anomaly.png", plot = anomaly_plot, width = 7, height = 4, dpi = 300)
ggsave("c02/anomaly.pdf", plot = anomaly_plot, width = 7, height = 4)


# ============================================================
# 10. INTERACTIVE PLOTS WITH PLOTLY ----
# ============================================================
# hover, zoom and toggle groups, in HTML only

seasonal_plot <- seasonal |>
  ggplot(aes(x = year, y = temp_mean, color = season)) +
  geom_line() +
  scale_color_manual(values = season_colors) +
  labs(
    x = NULL,
    y = "Mean temperature (°C)",
    color = NULL
  )

ggplotly(seasonal_plot)


# ============================================================
# 11. TRY IT: HOT DAYS PER DECADE ----
# ============================================================

# Your task: draw a bar chart of the average number of days of 30 °C or more per year, by
# decade (1900s to 2010s), with readable axis labels, a title, and the custom theme.


# ============================================================
# 12. TRY IT: THEN VS. NOW ----
# ============================================================

# Your task: compare the distribution of daily maximum temperatures in summer (June to
# August) for 1961–1990 and 1996–2025, as two overlapping densities in one plot, and as two
# facets of a histogram combined with patchwork.
