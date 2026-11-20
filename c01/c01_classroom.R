# ============================================================
# C01 · A MODERN R SETUP & WORKFLOW -- CLASSROOM QUICK-REFERENCE
# ============================================================


# ============================================================
# 1. PACKAGE MANAGEMENT WITH PACMAN ----
# ============================================================
# p_load() installs missing packages, then loads them

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, magrittr, broom)

tidyverse_packages()


# ============================================================
# 2. LOADING THE WEATHER DATA ----
# ============================================================
# daily DWD observations, -999 marks a missing value

karlsruhe_raw <- read_csv("data/dwd_karlsruhe.csv", na = "-999")
karlsruhe_raw

rheinstetten_raw <- read_csv("data/dwd_rheinstetten.csv", na = "-999")
rheinstetten_raw

karlsruhe_raw |> glimpse()


# ============================================================
# 3. PIPES ----
# ============================================================
# |> passes the left side on as the first argument, _ puts it into a named one;
# %$% exposes columns, %<>% pipes and assigns back

karlsruhe_raw |> nrow()
karlsruhe_raw |> lm(TXK ~ TNK, data = _)

karlsruhe_raw %$% cor(TXK, TNK)

rheinstetten_raw <- rheinstetten_raw |> filter(!is.na(TMK))
rheinstetten_raw %<>% filter(!is.na(TMK))


# ============================================================
# 4. DPLYR VERBS AND SQL ----
# ============================================================
# SELECT a, b             select(a, b)
# SELECT a AS new         rename(new = a), or select(new = a)
# SELECT a * 2 AS b       mutate(b = a * 2)
# SELECT DISTINCT a       distinct(a)
# WHERE a > 0             filter(a > 0)
# ORDER BY a DESC         arrange(desc(a))
# GROUP BY g              group_by(g)
# AVG(a), COUNT(*)        summarize(mean(a), n())
# HAVING n > 10           filter() after summarize()
# LIMIT 10                slice_head(n = 10)
# LEFT JOIN ... ON ...    left_join(by = ...)
# UNION ALL               bind_rows()


# ============================================================
# 5. CLEANING: ONE PIPELINE ----
# ============================================================
# readable names, a real date, only the columns we need

karlsruhe <- karlsruhe_raw |>
  select(MESS_DATUM, TMK, TXK, TNK, RSK, SDK, SHK_TAG) |>
  rename(
    temp_mean = TMK,
    temp_max = TXK,
    temp_min = TNK,
    precip = RSK,
    sunshine = SDK,
    snow = SHK_TAG
  ) |>
  mutate(
    date = ymd(MESS_DATUM),
    station = "Karlsruhe",
    .before = 1
  ) |>
  select(-MESS_DATUM)
karlsruhe

dwd_names <- c(
  temp_mean = "TMK",
  temp_max = "TXK",
  temp_min = "TNK",
  precip = "RSK",
  sunshine = "SDK",
  snow = "SHK_TAG"
)

rheinstetten <- rheinstetten_raw |>
  mutate(
    date = ymd(MESS_DATUM),
    station = "Rheinstetten",
    .before = 1
  ) |>
  select(date, station, all_of(dwd_names))
rheinstetten

# Missing values ----

karlsruhe |>
  summarize(across(everything(), ~ mean(is.na(.x))))

karlsruhe |>
  filter(!is.na(sunshine)) |>
  summarize(first_sunshine = min(date))

# across(): one function, many columns ----

karlsruhe |>
  summarize(across(where(is.numeric), \(x) mean(x, na.rm = TRUE)))

karlsruhe |>
  mutate(across(starts_with("temp_"), round))


# ============================================================
# 6. COMBINING DATA: BIND_ROWS() AND JOINS ----
# ============================================================
# Karlsruhe until 2008, Rheinstetten afterwards; joins compare and enrich

# bind_rows(): one long series ----

karlsruhe_end <- karlsruhe |>
  summarize(last = max(date)) |>
  pull(last)
karlsruhe_end

rheinstetten_after <- rheinstetten |>
  filter(date > karlsruhe_end)

weather <- bind_rows(karlsruhe, rheinstetten_after)
weather |>
  count(station)

# Joins: are the two stations comparable? ----

rheinstetten_temp <- rheinstetten |>
  select(date, temp_mean)

station_pairs <- karlsruhe |>
  select(date, temp_mean) |>
  inner_join(
    rheinstetten_temp,
    by = "date",
    suffix = c("_karlsruhe", "_rheinstetten")
  )
station_pairs

station_comparison <- station_pairs |>
  summarize(
    mean_diff = mean(temp_mean_karlsruhe - temp_mean_rheinstetten) |> round(2),
    correlation = cor(temp_mean_karlsruhe, temp_mean_rheinstetten) |> round(3)
  )
station_comparison

seasons <- tibble(
  month = 1:12,
  season = c("Winter", "Winter", "Spring", "Spring", "Spring", "Summer",
             "Summer", "Summer", "Autumn", "Autumn", "Autumn", "Winter")
)

weather <- weather |>
  mutate(month = month(date)) |>
  left_join(seasons, by = "month")
weather


# ============================================================
# 7. AGGREGATION: GROUP_BY(), MUTATE(), SUMMARIZE() ----
# ============================================================
# summarize() collapses rows, mutate() keeps them, group_by() makes both per group

yearly <- weather |>
  mutate(year = year(date)) |>
  filter(year < 2026) |>
  group_by(year) |>
  summarize(
    temp_mean = mean(temp_mean, na.rm = TRUE),
    precip = sum(precip, na.rm = TRUE),
    hot_days = sum(temp_max >= 30, na.rm = TRUE),
    frost_days = sum(temp_min < 0, na.rm = TRUE),
    n_days = n()
  )
yearly

yearly <- yearly |>
  filter(n_days >= 360)

reference_period <- 1961:1990

reference_temp <- yearly |>
  filter(year %in% reference_period) |>
  summarize(reference = mean(temp_mean)) |>
  pull(reference)
reference_temp

yearly <- yearly |>
  mutate(anomaly = temp_mean - reference_temp)

yearly |>
  arrange(desc(anomaly))

weather |>
  group_by(month) |>
  mutate(month_dev = temp_mean - mean(temp_mean, na.rm = TRUE)) |>
  ungroup() |>
  select(date, month, temp_mean, month_dev)


# ============================================================
# 8. SEVERAL ROWS PER GROUP: REFRAME() ----
# ============================================================
# summarize() returns one row per group, reframe() any number (and ungroups)

weather |>
  group_by(station) |>
  reframe(date = range(date))

# several values per group give several rows
probs <- c(0.1, 0.5, 0.9)

weather |>
  group_by(season) |>
  reframe(
    prob = probs,
    temp = quantile(temp_mean, probs, na.rm = TRUE)
  )


# ============================================================
# 9. RESHAPING: PIVOT_LONGER() AND PIVOT_WIDER() ----
# ============================================================
# long: one row per observation and measure; wide: one column per group

temps_wide <- weather |>
  select(date, temp_min, temp_mean, temp_max)
temps_wide

temps_long <- temps_wide |>
  pivot_longer(
    starts_with("temp_"),
    names_to = "measure",
    values_to = "temp",
    names_prefix = "temp_"
  )
temps_long

season_means <- weather |>
  mutate(year = year(date)) |>
  filter(year >= 2016, year <= 2025) |>
  group_by(year, season) |>
  summarize(temp_mean = mean(temp_mean, na.rm = TRUE)) |>
  ungroup()
season_means

season_means |>
  pivot_wider(names_from = season, values_from = temp_mean)


# ============================================================
# 10. SAVING THE CLEANED DATA ----
# ============================================================
# c02-c04 start from this file

weather |>
  write_csv("data/weather_karlsruhe.csv")


# ============================================================
# 11. R PROGRAMMING IN A NUTSHELL ----
# ============================================================
# operators, functions, conditions, rowwise() instead of loops, nesting

# Logical operators ----

weather |>
  filter(temp_max >= 35 | temp_min <= -15) |>
  select(date, temp_min, temp_max)

# Writing your own functions ----

celsius_to_fahrenheit <- function(celsius, digits = 1) {
  fahrenheit <- celsius * 9 / 5 + 32
  round(fahrenheit, digits)
}

celsius_to_fahrenheit(30)
celsius_to_fahrenheit(30, digits = 3)

weather |>
  mutate(temp_max_f = celsius_to_fahrenheit(temp_max)) |>
  select(date, temp_max, temp_max_f)

# Custom operators ----

# a custom infix operator: a name between % signs, in backticks
`%+-%` <- function(value, margin) {
  c(value - margin, value + margin)
}

20 %+-% 2.5

# Anonymous functions ----

yearly |>
  summarize(across(c(hot_days, frost_days), function(x) max(x)))
yearly |>
  summarize(across(c(hot_days, frost_days), \(x) max(x)))
yearly |>
  summarize(across(c(hot_days, frost_days), ~ max(.x)))

# Conditions: if/else, ifelse(), case_when() ----

latest_anomaly <- yearly |>
  slice_max(year) |>
  pull(anomaly)

if (latest_anomaly > 0)
  "warmer than 1961-1990" else
  "colder than 1961-1990"

yearly |>
  mutate(
    sign = ifelse(anomaly > 0, "warmer", "colder"),
    category = case_when(
      anomaly > 1.5 ~ "much warmer",
      anomaly > 0 ~ "warmer",
      anomaly > -1 ~ "colder",
      .default = "much colder"
    )
  ) |>
  count(category)

# Loops and their alternatives ----

# pluck(): one column as a plain vector
stations <- weather |>
  distinct(station) |>
  pluck("station")

season_names <- seasons |>
  distinct(season) |>
  pluck("season")

stations
season_names

for (station_name in stations) {
  n_days <- weather |>
    filter(station == station_name) |>
    nrow()
  print(str_glue("{station_name}: {n_days} days"))
}

for (station_name in stations) {
  for (season_name in season_names) {
    print(str_glue("{station_name} in {season_name}"))
  }
}

weather |>
  count(station)

expand_grid(
  station = stations,
  season = season_names
) |>
  mutate(label = str_glue("{station} in {season}"))

# rowwise() ----

classify_anomaly <- function(anomaly) {
  if (anomaly > 0)
    "warmer" else
    "colder"
}

classify_anomaly(0.8)

# fails: if() only takes a single value
# yearly |>
#   mutate(sign = classify_anomaly(anomaly))

yearly |>
  rowwise() |>
  mutate(sign = classify_anomaly(anomaly)) |>
  ungroup() |>
  select(year, anomaly, sign)

# purrr's map_*(): the same on a vector
c(0.8, -0.3) |>
  map_chr(classify_anomaly)

# expand_grid() sets up the combinations, rowwise() calls a function once per row
feels_like <- function(temp, wind) {
  if (temp > 10)
    temp else
    13.12 + 0.6215 * temp - 11.37 * wind^0.16 + 0.3965 * temp * wind^0.16
}

conditions <- expand_grid(
  temp = c(-10, 0, 10, 20),
  wind = c(10, 30, 50)
)

conditions |>
  rowwise() |>
  mutate(feels = round(feels_like(temp, wind), 1)) |>
  ungroup()

# the same in parallel with multidplyr: load packages and copy the function to the sessions first
p_load(multidplyr)

cluster <- new_cluster(2)
cluster |>
  cluster_library("tidyverse") |>
  cluster_copy("feels_like")

conditions |>
  rowwise() |>
  partition(cluster) |>
  mutate(feels = round(feels_like(temp, wind), 1)) |>
  collect() |>
  arrange(temp, wind)

# Nesting: one model per group ----

season_years <- weather |>
  mutate(year = year(date)) |>
  filter(year >= 1950, year <= 2025) |>
  group_by(season, year) |>
  summarize(temp_mean = mean(temp_mean, na.rm = TRUE)) |>
  ungroup()
season_years

season_data <- season_years |>
  nest(data = c(year, temp_mean))
season_data

season_models <- season_data |>
  rowwise() |>
  mutate(model = list(lm(temp_mean ~ year, data = data)))
season_models

# tidy() each model, unnest() to one long tibble
season_coefficients <- season_models |>
  mutate(coefficients = list(tidy(model))) |>
  ungroup() |>
  select(season, coefficients)
season_coefficients

season_coefficients |>
  unnest(coefficients) |>
  filter(term == "year") |>
  mutate(per_decade = estimate * 10)


# ============================================================
# 12. BIGGER DATA: DUCKDB AND DUCKPLYR ----
# ============================================================
# run make_big_data.R once (1 GB, ~1 min); elapsed = seconds

source("data/make_big_data.R")

big_file <- "data/big/weather_big.csv"

# in memory: read everything, then compute
read_csv(big_file) |>
  filter(year >= 1996) |>
  summarize(hot_days = sum(temp_max >= 30, na.rm = TRUE), .by = station) |>
  arrange(desc(hot_days)) |>
  system.time()

# DuckDB: only records the steps, collect() runs the whole query
p_load(duckplyr)

read_csv_duckdb(big_file) |>
  filter(year >= 1996) |>
  summarize(hot_days = sum(temp_max >= 30, na.rm = TRUE), .by = station) |>
  arrange(desc(hot_days)) |>
  collect() |>
  system.time()

hot_days_big <- read_csv_duckdb(big_file) |>
  filter(year >= 1996) |>
  summarize(hot_days = sum(temp_max >= 30, na.rm = TRUE), .by = station) |>
  arrange(desc(hot_days)) |>
  collect()
hot_days_big

# copy the CSV into a DuckDB database file once, then query the table
p_load(duckdb, dbplyr)

con <- dbConnect(duckdb(), "data/big/weather_big.duckdb")

dbExecute(
  con,
  "CREATE OR REPLACE TABLE weather AS SELECT * FROM read_csv('data/big/weather_big.csv')"
) |>
  system.time()

tbl(con, "weather") |>
  filter(year >= 1996) |>
  summarize(hot_days = sum(temp_max >= 30, na.rm = TRUE), .by = station) |>
  arrange(desc(hot_days)) |>
  collect() |>
  system.time()

dbDisconnect(con)


# ============================================================
# 13. TRY IT: THE SUNNIEST AND RAINIEST DECADES ----
# ============================================================

# Your task: starting from weather, compute the average yearly sunshine hours and
# precipitation per decade (only complete decades from the 1900s on), sorted by sunshine.


# ============================================================
# 14. TRY IT: SUMMER DAYS PER SEASON AND STATION ----
# ============================================================

# Your task: count the days with at least 25 °C maximum temperature (a "Sommertag", summer
# day) per season, separately for both stations during their 1948–1985 overlap. Show one row
# per season and one column per station.


# ============================================================
# 15. TRY IT: SEASONAL QUANTILES OF THE EXTREMES ----
# ============================================================

# Your task: for each season, compute the 5%, 50% and 95% quantiles of both the daily
# minimum and the daily maximum temperature, with one row per season and quantile.


# ============================================================
# 16. TRY IT: HAS THE WARMING SPED UP? ----
# ============================================================

# Your task: for each season, compute the warming trend in °C per decade twice, once for the
# years 1950–2025 and once for 1990–2025. Label each trend as "fast" (more than 0.3 °C per
# decade), "slow" (above 0) or "none".
