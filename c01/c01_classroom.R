# ============================================================
# C01 · A MODERN R SETUP & WORKFLOW -- CLASSROOM QUICK-REFERENCE
# ============================================================


# ============================================================
# 1. PACKAGE MANAGEMENT WITH PACMAN ----
# ============================================================
# p_load() installs missing packages, then loads them

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, magrittr)

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
# 4. CLEANING: ONE PIPELINE ----
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


# ============================================================
# 5. COMBINING DATA: BIND_ROWS() AND JOINS ----
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
# 6. AGGREGATION: GROUP_BY(), MUTATE(), SUMMARIZE() ----
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
# 7. RESHAPING: PIVOT_LONGER() AND PIVOT_WIDER() ----
# ============================================================
# long: one row per observation and measure; wide: one column per group

temps_long <- weather |>
  select(date, temp_min, temp_mean, temp_max) |>
  pivot_longer(
    starts_with("temp_"),
    names_to = "measure",
    values_to = "temp",
    names_prefix = "temp_"
  )
temps_long

weather |>
  mutate(year = year(date)) |>
  filter(year >= 2016, year <= 2025) |>
  group_by(year, season) |>
  summarize(temp_mean = mean(temp_mean, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = season, values_from = temp_mean)


# ============================================================
# 8. SAVING THE CLEANED DATA ----
# ============================================================
# c02-c04 start from this file

weather |>
  write_csv("data/weather_karlsruhe.csv")


# ============================================================
# 9. R PROGRAMMING IN A NUTSHELL ----
# ============================================================
# operators, functions, conditions and loops, the tidyverse way

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

for (station_name in c("Karlsruhe", "Rheinstetten")) {
  n_days <- weather |>
    filter(station == station_name) |>
    nrow()
  print(str_glue("{station_name}: {n_days} days"))
}

weather |>
  count(station)

c("Karlsruhe", "Rheinstetten") |>
  map_int(\(s) nrow(filter(weather, station == s)))

expand_grid(
  station = c("Karlsruhe", "Rheinstetten"),
  season = c("Winter", "Spring", "Summer", "Autumn")
) |>
  mutate(label = str_glue("{station} in {season}"))

classify_anomaly <- function(anomaly) {
  if (anomaly > 0)
    "warmer" else
    "colder"
}

yearly |>
  rowwise() |>
  mutate(sign = classify_anomaly(anomaly)) |>
  ungroup() |>
  select(year, anomaly, sign)


# ============================================================
# 10. TRY IT: THE SUNNIEST AND RAINIEST DECADES ----
# ============================================================

# Your task: starting from weather, compute the average yearly sunshine hours and
# precipitation per decade (only complete decades from the 1900s on), sorted by sunshine.


# ============================================================
# 11. TRY IT: SUMMER DAYS PER SEASON AND STATION ----
# ============================================================

# Your task: count the days with at least 25 °C maximum temperature (a "Sommertag", summer
# day) per season, separately for both stations during their 1948–1985 overlap. Show one row
# per season and one column per station.
