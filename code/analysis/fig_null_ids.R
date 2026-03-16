# code/analysis/fig_null_ids.R
# Outputs: Fig B1–B4
#   Line plots of % null IDs and % null values over time,
#   one panel per in-sample state, for each MiDES table:
#   - Fig B1: commitments (empenho)
#   - Fig B2: verifications (liquidacao)
#   - Fig B3: payments (pagamento)
#   - Fig B4: tenders (licitacao)
#
# Input CSVs (pre-downloaded by code/build/ingest_bigquery.R):
#   null_budget_commitment_ids.csv
#   null_budget_verification_ids.csv
#   null_budget_payment_ids.csv
#   null_tender_ids.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES <- c("CE", "MG", "PB", "PR", "RS", "SP")

# ---- Helper: load, compute proportions, filter ----

load_null_csv <- function(filename, filter_rs_pre2010 = TRUE, filter_pb_pre2009 = FALSE) {
  dt <- fread(file.path(input, filename))

  # Compute % proportions
  dt[, proportion_ids   := 100 * total_null_ids   / total_observations]
  dt[, proportion_value := 100 * total_null_value / total_value]

  # Apply known data quality filters
  if (filter_rs_pre2010)  dt <- dt[!(state == "RS" & year < 2010)]
  if (filter_pb_pre2009)  dt <- dt[!(state == "PB" & year < 2009)]

  dt[state %in% STATES]
}

# ---- Helper: 3×2 line plot (one panel per state) ----

make_null_plot <- function(dt, y_label) {
  dt[, state := factor(state, levels = STATES)]

  # Melt to long for two lines per panel
  dt_long <- melt(dt,
                  id.vars       = c("state", "year"),
                  measure.vars  = c("proportion_ids", "proportion_value"),
                  variable.name = "series",
                  value.name    = "pct")

  dt_long[, series_label := fifelse(series == "proportion_ids",
                                    "% Null IDs", "% Null Values")]

  ggplot(dt_long, aes(x = year, y = pct, color = series_label, linetype = series_label)) +
    geom_line(linewidth = 0.8) +
    scale_color_manual(values = c("% Null IDs" = "#1A476F", "% Null Values" = "#C0392B"),
                       name = NULL) +
    scale_linetype_manual(values = c("% Null IDs" = "solid", "% Null Values" = "dashed"),
                          name = NULL) +
    scale_x_continuous("Year", breaks = seq(2008, 2022, by = 2)) +
    scale_y_continuous(y_label) +
    facet_wrap(~state, nrow = 2, ncol = 3, scales = "free_y") +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 10, y_text_size = 10, size = 11,
              legend_position = "bottom") +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text = element_text(size = 11, family = "LM Roman 10"),
          axis.text.x = element_text(angle = 45, hjust = 1))
}

# ---- Fig B1: Commitments ----

dt_comm <- load_null_csv("null_budget_commitment_ids.csv")
p_comm  <- make_null_plot(dt_comm, "% of Observations")
ggsave(file.path(graph_output, "proporcao_nulos_empenhos.pdf"),
       p_comm, width = 12, height = 7, device = cairo_pdf)

# ---- Fig B2: Verifications ----

dt_verif <- load_null_csv("null_budget_verification_ids.csv")
p_verif  <- make_null_plot(dt_verif, "% of Observations")
ggsave(file.path(graph_output, "proporcao_nulos_liquidacao.pdf"),
       p_verif, width = 12, height = 7, device = cairo_pdf)

# ---- Fig B3: Payments ----

dt_pay <- load_null_csv("null_budget_payment_ids.csv")
p_pay  <- make_null_plot(dt_pay, "% of Observations")
ggsave(file.path(graph_output, "proporcao_nulos_pagamento.pdf"),
       p_pay, width = 12, height = 7, device = cairo_pdf)

# ---- Fig B4: Tenders ----

dt_lic <- load_null_csv("null_tender_ids.csv")
p_lic  <- make_null_plot(dt_lic, "% of Observations")
ggsave(file.path(graph_output, "proporcao_nulos_licitacao.pdf"),
       p_lic, width = 12, height = 7, device = cairo_pdf)
