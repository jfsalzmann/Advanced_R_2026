# global.R: runs once at startup, shared by ui.R and server.R
# Run from the project root: shiny::runApp("c04/app_two_files")

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
