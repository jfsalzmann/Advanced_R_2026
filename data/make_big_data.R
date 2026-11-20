# Creates data/big/weather_big.csv (~1 GB): simulated daily weather for 650 fictional stations,
# 1876-2025, used in the "Bigger data" section of c01.
# Run once from the project root: source("data/make_big_data.R")
# Takes about a minute. data/big/ is not tracked by git.

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse)

set.seed(2026)
dir.create("data/big", showWarnings = FALSE)
big_file <- "data/big/weather_big.csv"

dates <- seq(ymd("1876-01-01"), ymd("2025-12-31"), by = "day")

# 50 stations at a time, appended to the file, so memory use stays small
write_block <- function(block) {
  expand_grid(
    station = (block - 1) * 50 + 1:50,
    date = dates
  ) |>
    group_by(station) |>
    mutate(offset = rnorm(1, mean = 0, sd = 2)) |>
    ungroup() |>
    mutate(
      season_curve = 9 * sin(2 * pi * (yday(date) - 110) / 365),
      temp_mean = round(10 + season_curve + offset + rnorm(n(), sd = 3), 1),
      temp_max = round(temp_mean + runif(n(), min = 2, max = 8), 1),
      temp_min = round(temp_mean - runif(n(), min = 2, max = 8), 1),
      precip = round(rexp(n(), rate = 0.5) * rbinom(n(), size = 1, prob = 0.45), 1)
    ) |>
    mutate(
      year = year(date),
      day = yday(date)
    ) |>
    select(station, year, day, temp_mean, temp_max, temp_min, precip) |>
    write_csv(big_file, append = block > 1)
}

walk(1:13, write_block)
