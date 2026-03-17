# code/analysis/fig_validation_siconfi.R
# Outputs: Fig 3–5 and Fig A1–A4
#   Histograms of % difference between MiDES and SICONFI for
#   commitments, verifications, and payments (by municipality and by function).
#
# Input CSVs (pre-downloaded by code/build/ingest_bigquery.R):
#   commitment_municipality_year.csv        — columns: ano, sigla_uf, id_municipio, ..., proportion
#   commitment_function_municipality_year.csv
#   verification_municipality_year.csv
#   verification_function_municipality_year.csv
#   payment_municipality_year.csv
#   payment_function_municipality_year.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

# ---- Constants ----

STATES <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")
CAP    <- 25   # cap proportions at ±25 pp for display

# ---- Helper: load, standardise, filter ----

load_validation_csv <- function(filename, filter_rs_pre2010 = TRUE) {
  dt <- fread(file.path(bigquery, filename))

  # Standardise column names (all CSVs use ano/sigla_uf)
  setnames(dt, "ano",      "year",  skip_absent = TRUE)
  setnames(dt, "sigla_uf", "state", skip_absent = TRUE)

  # Drop infinite / NA proportions
  dt <- dt[is.finite(proportion) & !is.na(proportion)]

  # Known data quality filter
  if (filter_rs_pre2010 && "year" %in% names(dt))
    dt <- dt[!(state == "RS" & year < 2010)]

  dt <- dt[state %in% STATES]

  # Cap at ±25 pp
  dt[, proportion := pmax(pmin(proportion, CAP), -CAP)]
  dt
}

# ---- Helper: 7-panel histogram (one per state) ----

make_histogram_plot <- function(dt, x_label) {
  dt[, state := factor(state, levels = STATES)]

  ggplot(dt, aes(x = proportion)) +
    geom_histogram(bins = 20, boundary = -CAP, closed = "left",
                   fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "black", linewidth = 0.5, linetype = "dashed") +
    scale_x_continuous(x_label,
                       limits = c(-CAP - 0.5, CAP + 0.5),
                       breaks = seq(-25, 25, by = 5),
                       labels = {
                         brks <- seq(-25, 25, by = 5)
                         lbs  <- as.character(brks)
                         lbs[1] <- "<-25"
                         lbs[length(lbs)] <- "25>"
                         lbs
                       }) +
    scale_y_continuous("Frequency") +
    facet_wrap(~state, nrow = 4, scales = "free_y") +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 11, y_text_size = 11, size = 12) +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text = element_text(size = 11, family = "LM Roman 10"))
}

# ---- Helper: year-panel histogram (for one state × 8 years) ----

make_year_hist <- function(dt, state_code, years, x_label) {
  dt <- dt[state == state_code & year %in% years]
  dt[, year := factor(year)]

  ggplot(dt, aes(x = proportion)) +
    geom_histogram(bins = 20, boundary = -CAP, closed = "left",
                   fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "black", linewidth = 0.5, linetype = "dashed") +
    scale_x_continuous(x_label,
                       limits = c(-CAP - 0.5, CAP + 0.5),
                       breaks = seq(-25, 25, by = 5),
                       labels = {
                         brks <- seq(-25, 25, by = 5)
                         lbs  <- as.character(brks)
                         lbs[1] <- "<-25"
                         lbs[length(lbs)] <- "25>"
                         lbs
                       }) +
    scale_y_continuous("Frequency") +
    facet_wrap(~year, nrow = 2, scales = "free_y") +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 11, y_text_size = 11, size = 12) +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text = element_text(size = 11, family = "LM Roman 10"))
}

# ---- Fig 3: Commitment (by municipality) ----

dt_comm <- load_validation_csv("commitment_municipality_year.csv")
ggsave(file.path(graph_output, "Dahis Fig 3.png"),
       make_histogram_plot(dt_comm, "% Difference (Commitment)"),
       width = 15, height = 9, dpi = 300)

# ---- Fig A1: Commitment (by function) ----

dt_comm_fn <- load_validation_csv("commitment_function_municipality_year.csv")
ggsave(file.path(graph_output, "validation_siconfi_commitment_function.png"),
       make_histogram_plot(dt_comm_fn, "% Difference (Commitment by Function)"),
       width = 15, height = 9, dpi = 300)

# ---- Fig 4: Verification (by municipality) ----

dt_verif <- load_validation_csv("verification_municipality_year.csv")
ggsave(file.path(graph_output, "Dahis Fig 4.png"),
       make_histogram_plot(dt_verif, "% Difference (Verification)"),
       width = 15, height = 9, dpi = 300)

# ---- Fig A2: Verification (by function) ----

dt_verif_fn <- load_validation_csv("verification_function_municipality_year.csv")
ggsave(file.path(graph_output, "validation_siconfi_verification_function.png"),
       make_histogram_plot(dt_verif_fn, "% Difference (Verification by Function)"),
       width = 15, height = 9, dpi = 300)

# ---- Fig 5: Payment (by municipality) ----

dt_pay <- load_validation_csv("payment_municipality_year.csv")
ggsave(file.path(graph_output, "Dahis Fig 5.png"),
       make_histogram_plot(dt_pay, "% Difference (Payment)"),
       width = 15, height = 9, dpi = 300)

# ---- Fig A3: Payment (by function) ----

dt_pay_fn <- load_validation_csv("payment_function_municipality_year.csv")
ggsave(file.path(graph_output, "validation_siconfi_payment_function.png"),
       make_histogram_plot(dt_pay_fn, "% Difference (Payment by Function)"),
       width = 15, height = 9, dpi = 300)

# ---- Fig A4a: Payment by year — PR (2013-2020) ----

dt_pay_all <- load_validation_csv("payment_municipality_year.csv", filter_rs_pre2010 = FALSE)
ggsave(file.path(graph_output, "validation_siconfi_payment_pr.png"),
       make_year_hist(dt_pay_all, "PR", 2013:2020, "% Difference (Payment — PR)"),
       width = 15, height = 9, dpi = 300)

# ---- Fig A4b: Payment by year — MG (2014-2021) ----

ggsave(file.path(graph_output, "validation_siconfi_payment_mg.png"),
       make_year_hist(dt_pay_all, "MG", 2014:2021, "% Difference (Payment — MG)"),
       width = 15, height = 9, dpi = 300)
