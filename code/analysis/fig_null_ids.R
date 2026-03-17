# code/analysis/fig_null_ids.R
# Outputs: Fig B1–B4
#   Line plots of % null IDs and % null values over time,
#   one panel per in-sample state, for each MiDES table.

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES <- c("CE", "MG", "PB", "PR", "RS", "SP")

# ---- Helper: 3×2 dual-line plot ----

make_null_plot <- function(dt) {
  dt[, state := factor(state, levels = STATES)]

  dt_long <- melt(dt,
                  id.vars      = c("state", "year"),
                  measure.vars = c("proportion_ids", "proportion_value"),
                  variable.name = "series", value.name = "pct")
  dt_long[, series_label := fifelse(series == "proportion_ids",
                                    "% Null IDs", "% Null Values")]

  ggplot(dt_long, aes(x = year, y = pct, color = series_label, linetype = series_label)) +
    geom_line(linewidth = 0.8) +
    scale_color_manual(values = c("% Null IDs" = "#1A476F", "% Null Values" = "#C0392B"),
                       name = NULL) +
    scale_linetype_manual(values = c("% Null IDs" = "solid", "% Null Values" = "dashed"),
                          name = NULL) +
    scale_x_continuous("Year", breaks = seq(2008, 2022, by = 2)) +
    scale_y_continuous("% of Observations") +
    facet_wrap(~state, nrow = 2, ncol = 3, scales = "free_y") +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 10, y_text_size = 10, size = 11,
              legend_position = "bottom",
              axis_text_x = element_markdown(size = 10, angle = 45, hjust = 1,
                                             family = "LM Roman 10")) +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text  = element_text(size = 11, family = "LM Roman 10"))
}

# ---- Fig B1: Commitments ----
# Columns: year, state, total_observations, total_commitments,
#          total_null_commtiments (sic), total_committed, total_null_committed

dt_comm <- fread(file.path(bigquery, "null_budget_commitment_ids.csv"))
dt_comm <- dt_comm[!(state == "RS" & year < 2010)][state %in% STATES]
dt_comm[, proportion_ids   := 100 * total_null_commtiments / total_commitments]
dt_comm[, proportion_value := 100 * total_null_committed   / total_committed]

ggsave(file.path(graph_output, "proporcao_nulos_empenhos.pdf"),
       make_null_plot(dt_comm), width = 12, height = 7, device = cairo_pdf)

# ---- Fig B2: Verifications ----
# Columns: year, state, total_observations, total_verifications,
#          total_null_verifications, total_verified, total_null_verified

dt_verif <- fread(file.path(bigquery, "null_budget_verification_ids.csv"))
dt_verif <- dt_verif[!(state == "RS" & year < 2010)][state %in% STATES]
dt_verif[, proportion_ids   := 100 * total_null_verifications / total_verifications]
dt_verif[, proportion_value := 100 * total_null_verified      / total_verified]

ggsave(file.path(graph_output, "proporcao_nulos_liquidacao.pdf"),
       make_null_plot(dt_verif), width = 12, height = 7, device = cairo_pdf)

# ---- Fig B3: Payments ----
# Columns: year, state, total_observations, total_payments,
#          total_null_payments, total_paid, total_null_paid

dt_pay <- fread(file.path(bigquery, "null_budget_payment_ids.csv"))
dt_pay <- dt_pay[!(state == "RS" & year < 2010)][state %in% STATES]
dt_pay[, proportion_ids   := 100 * total_null_payments / total_payments]
dt_pay[, proportion_value := 100 * total_null_paid     / total_paid]

ggsave(file.path(graph_output, "proporcao_nulos_pagamento.pdf"),
       make_null_plot(dt_pay), width = 12, height = 7, device = cairo_pdf)

# ---- Fig B4: Tenders ----
# Columns: year, state, total_observations, total_tenders,
#          total_null_tenders, total_procurement_value, total_null_tenders_value

dt_lic <- fread(file.path(bigquery, "null_tender_ids.csv"))
dt_lic <- dt_lic[state %in% STATES]
dt_lic[, proportion_ids   := 100 * total_null_tenders       / total_tenders]
dt_lic[, proportion_value := 100 * total_null_tenders_value / total_procurement_value]

ggsave(file.path(graph_output, "proporcao_nulos_licitacao.pdf"),
       make_null_plot(dt_lic), width = 12, height = 7, device = cairo_pdf)
