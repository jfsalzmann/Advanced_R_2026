# Advanced R for Data Analysis and Reporting

One-day workshop, KIT House of Competence, Friday 20.11.2026, 09:00–18:00.
Instructor: Johann-Friedrich Salzmann ([jf.salzmann@uni-mannheim.de](mailto:jf.salzmann@uni-mannheim.de))

## Modules

| | Topic | Script | More |
|---|---|---|---|
| c01 | A modern R setup & workflow | [`c01/c01_classroom.R`](c01/c01_classroom.R) | |
| c02 | Advanced visualization with ggplot2 | [`c02/c02_classroom.R`](c02/c02_classroom.R) | |
| c03 | Quarto reports | [`c03/c03_classroom.R`](c03/c03_classroom.R) | example project in [`c03/report/`](c03/report/) |
| c04 | Shiny apps | [`c04/c04_classroom.R`](c04/c04_classroom.R) | the app in [`c04/app/`](c04/app/) and [`c04/app_two_files/`](c04/app_two_files/) |

Each module's classroom script is a quick reference of the code shown in class. The full
module pages (HTML and PDF) and the slides follow after the course.

## Setup

1. Install [R 4.6.x](https://www.r-project.org/), [Positron](https://positron.posit.co/download.html)
   and [GitHub Desktop](https://desktop.github.com/download/).
2. Clone this repository (GitHub Desktop: *File → Clone repository*), and open the folder in
   Positron (*File → Open Folder*). All code assumes this folder as the working directory.
3. Install the packages:

```r
if (!require(pacman)) install.packages("pacman")
p_load(tidyverse, magrittr, broom, duckplyr, duckdb, dbplyr, scales, patchwork, plotly, quarto,
       tinytable, shiny, bslib)
```

## Data

Daily climate observations of the Deutscher Wetterdienst for the stations Karlsruhe (ID 2522,
1876–2008) and Rheinstetten (ID 4177, since 1948), from the
[DWD Climate Data Center](https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/historical/).
Datenbasis: Deutscher Wetterdienst.

- `data/dwd_karlsruhe.csv`, `data/dwd_rheinstetten.csv`: the original files, converted to CSV
- `data/weather_karlsruhe.csv`: cleaned and combined series, written in c01
