# code/utils/paths.R
# Centralised path configuration for the MiDES replication package.
# Source this file at the top of every analysis script:
#   source(here::here("code/utils/paths.R"))

if (!require("here", quietly = TRUE)) install.packages("here")
library(here)

# ---- Dropbox root (data lives here, never in git) ----

if (Sys.getenv("USER") == "rdahis") {                         # Ricardo (Monash)
  dropbox_dir <- "/Users/rdahis/Monash Uni Enterprise Dropbox/Ricardo Dahis/Academic/Papers/MiDES-data-paper-replication"

} else if (Sys.getenv("USERNAME") == "natha") {               # Nathalia
  dropbox_dir <- "C:\\Users\\natha\\Dropbox\\MiDES-data-paper-replication"

} else if (Sys.getenv("USER") == "tscot") {                   # Thiago (WB)
  dropbox_dir <- "/Users/tscot/Dropbox/MiDES-data-paper-replication"

} else if (Sys.getenv("USERNAME") == "wb463689") {            # Thiago (WB internal)
  dropbox_dir <- ""

} else if (Sys.getenv("USER") == "ruggerodoino") {            # RA (World Bank-DIME)
  dropbox_dir <- ""

} else {
  stop("Unknown user. Please add your Dropbox path to code/utils/paths.R")
}

# ---- Input data ----
input        <- file.path(dropbox_dir, "Data/Raw")
intermediate <- file.path(dropbox_dir, "Data/Intermediate")

# BigQuery extracts (SQL-originated CSVs downloaded by code/build/ingest_bigquery.R).
# These are NOT raw data — they are the result of BigQuery queries against the
# basedosdados.world_wb_mides.* and related datasets.
bigquery     <- file.path(intermediate, "BigQuery")

# ---- Outputs (relative to repo root, cleared by main.sh before each run) ----
graph_output <- here::here("output/figures")
table_output <- here::here("output/tables")

# ---- Utility code (for backward-compat sourcing if needed) ----
utils_dir <- here::here("code/utils")

# Create output directories if they don't exist
dir.create(graph_output, recursive = TRUE, showWarnings = FALSE)
dir.create(table_output, recursive = TRUE, showWarnings = FALSE)
