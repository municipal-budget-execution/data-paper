# code/utils/packages.R
# Declares all R packages required by the MiDES replication package.
# Source this file (or let paths.R source it) to install and load everything.
#
# Usage:
#   source(here::here("code/utils/packages.R"))

if (!require("pacman", quietly = TRUE)) install.packages("pacman")

pacman::p_load(
  char = c(
    # Data manipulation
    "data.table", "dplyr",
    # Plotting
    "ggplot2", "ggpubr", "ggtext", "ggrepel",
    # Maps
    "sf", "geobr",
    # Regression / econometrics
    "fixest", "binsreg", "rdrobust",
    # Tables
    "modelsummary", "kableExtra",
    # Data I/O and utilities
    "here", "DescTools", "scales", "stringr", "stringi", "tinytex",
    "readxl", "haven", "janitor"
    # "basedosdados"  # uncomment only for --redownload
  ),
  install = TRUE
)

# Global options
options(scipen = 9999)
set.seed(123)
