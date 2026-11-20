# ============================================================
# C03 · QUARTO REPORTS -- CLASSROOM QUICK-REFERENCE
# ============================================================
# The worked example is the project in c03/report/: open report.qmd next to this script.
# Quarto syntax isn't R, so most of this script is a commented cheat sheet.


# ============================================================
# 1. PACKAGES ----
# ============================================================

if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, quarto)


# ============================================================
# 2. A PROJECT'S FILE STRUCTURE ----
# ============================================================
# report/
# ├── _quarto.yml       shared settings for every .qmd in the folder
# ├── report.qmd        the report: YAML header, text, code chunks
# ├── references.bib    bibliography (BibTeX)
# ├── data/             input data
# └── images/           static images
#
# _quarto.yml:
#   execute:
#     freeze: auto
#     echo: false
#   format:
#     html:
#       toc: true
#       embed-resources: true
#     typst:
#       toc: true
#       papersize: a4
#   bibliography: references.bib
#
# report.qmd header:
#   ---
#   title: "Karlsruhe Is Getting Warmer"
#   author: "Your Name"
#   date: today
#   ---


# ============================================================
# 3. OUTPUT FORMATS AND RENDERING ----
# ============================================================
# HTML (interactive), Typst PDF (fast, no LaTeX), LaTeX PDF (format: pdf), docx, revealjs
# Terminal: quarto render report.qmd / quarto render report.qmd --to typst /
#           quarto preview report.qmd
# Running chunks inline uses your session; rendering starts a fresh one, top to bottom

quarto_render("c03/report/report.qmd")


# ============================================================
# 4. CODE CHUNKS AND INLINE CODE ----
# ============================================================
# ```{r}
# #| label: fig-anomaly
# #| fig-cap: "Annual mean temperature, deviation from the 1961-1990 mean."
# #| echo: false
# yearly |>
#   ggplot(aes(x = year, y = anomaly)) +
#   geom_col()
# ```
#
# echo: false      hide the code, show the output
# eval: false      show the code, don't run it
# include: false   run it, show nothing
# warning: false / message: false
# fig-cap, fig-width, fig-height
# cache: true
#
# Inline code, one variable computed in a chunk before:
# The warmest year on record is `r warmest_year`.


# ============================================================
# 5. FIGURES, TABLES, IMAGES ----
# ============================================================
# figure: chunk label fig-... + fig-cap, refer to it with @fig-anomaly
# table:  chunk label tbl-... + tbl-cap, refer to it with @tbl-days
#
# ```{r}
# #| label: tbl-days
# #| tbl-cap: "Average number of days per year."
# period_means |>
#   knitr::kable(digits = 1)
# ```
#
# alternative: tinytable, styled and adapts to HTML and Typst on its own
# p_load(tinytable)
# period_means |>
#   tt() |>
#   format_tt(digits = 1, num_fmt = "decimal")
#
# image:![Warming stripes for Karlsruhe.](images/stripes.png){#fig-stripes width=80%}


# ============================================================
# 6. TEXT: FORMATTING, LINKS, FORMULAS ----
# ============================================================
# **bold**, *italic*, `code`, [a link](https://quarto.org)
# ## A section heading
# - a bullet point
# 1. a numbered item
# Inline math: $\Delta T_t$, display math between $$ ... $$
# Formulas are LaTeX by default. Typst math instead: github.com/jfsalzmann/quarto-typst-equations
# Typst: typst.app, math syntax: typst.app/docs/reference/math/
# LaTeX to Typst: qwinsi.github.io/tex2typst-webapp/


# ============================================================
# 7. REFERENCES ----
# ============================================================
# Data: Deutscher Wetterdienst [@dwd2026], analysed with the tidyverse [@wickham2023].
# entries in references.bib; the bibliography goes at the end, or into a ::: {#refs} block


# ============================================================
# 8. REPRODUCIBILITY AT A GLANCE ----
# ============================================================
# set.seed() random draws that repeat
# targets   pipelines: works out the dependencies of a whole project, re-runs outdated steps
# renv      package versions in a lockfile
# Docker    the whole system (OS, R, packages) in an image


# ============================================================
# 9. CACHING: ONLY RE-RUN WHAT CHANGED ----
# ============================================================
# freeze: auto (_quarto.yml)   re-run a document only when its .qmd changed
# #| cache: true                re-run a chunk only when its code changed
# #| cache.extra: !expr file.mtime("data/weather_karlsruhe.csv")
#                               ... or when the data file changed
# #| dependson: "load-data"     ... or when another cached chunk changed

# in a chunk with #| cache: true, this takes 3 s the first time, none after that
Sys.sleep(3) # stand-in for a slow step
weather <- read_csv("data/weather_karlsruhe.csv")
weather |>
  summarize(days = n())


# ============================================================
# 10. RANDOM NUMBERS AND SEEDS ----
# ============================================================
# every run draws different numbers; set.seed() makes them reproducible

rnorm(3)
runif(3)

set.seed(2026)
runif(3)

set.seed(2026)
runif(3)

# Sampling rows from a tibble ----

weather |>
  slice_sample(n = 3)

weather |>
  slice_sample(n = 2, by = season)

# with replacement: a bootstrap sample
weather |>
  slice_sample(prop = 1, replace = TRUE) |>
  summarize(temp_mean = mean(temp_mean, na.rm = TRUE))


# ============================================================
# 11. TRY IT: YOUR OWN REPORT ----
# ============================================================

# Your task: create a folder c03/my_report/ with a _quarto.yml and one .qmd, rendering to
# HTML and Typst PDF. The report should answer one question about the weather data (e.g. "Is
# it getting sunnier?", "Do we get less snow?") with at least one numbered figure, one
# table, one inline number, one citation, and a cached data-loading chunk. Refer to the
# figure and the table in the text.
