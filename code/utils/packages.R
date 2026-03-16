# code/utils/packages.R
# Declares all R packages required by the MiDES replication package.
# Source this file (or let paths.R source it) to install and load everything.
#
# Usage:
#   source(here::here("code/utils/packages.R"))

if (!require("pacman", quietly = TRUE)) install.packages("pacman")

pacman::p_load(
  # Data manipulation
  "data.table",
  "dplyr",

  # Plotting
  "ggplot2",
  "ggpubr",
  "ggtext",

  # Maps
  "sf",
  "geobr",

  # Regression / econometrics
  "fixest",
  "binsreg",

  # Tables
  "modelsummary",
  "kableExtra",

  # Utilities
  "here",
  "DescTools",

  # BigQuery (only needed for --redownload)
  # "basedosdados",   # uncomment if re-downloading raw data

  install = TRUE,
  character.only = TRUE
)

# Global options
options(scipen = 9999)
set.seed(123)
