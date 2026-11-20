# Solutions for the Try-its without a solution in the course files

The c01 and c02 Try-it solutions are in the module HTML files themselves (collapsed below each
task), so they aren't repeated here.

| Try-it | Solution | Run / open |
|---|---|---|
| c03: your own report | `c03_my_report/` ("Is Karlsruhe getting sunnier?"), pre-rendered | `my_report.html` / `.pdf`; re-render with `quarto render` inside the folder |
| c04: extend the app | `c04_extend_app/`: all four suggested features in one app | `shiny::runApp("solutions/c04_extend_app")` |
| c04: your own app (hot days) | `c04_own_app_hot_days/` | `shiny::runApp("solutions/c04_own_app_hot_days")` |
| c04: your own app (heatmap) | `c04_own_app_heatmap/` | `shiny::runApp("solutions/c04_own_app_heatmap")` |

Each folder has its own copy of `weather_karlsruhe.csv`, like `c04/app/`, so it runs and deploys
on its own.
