# code/analysis/fig_total_municipalities.R
# Outputs: Fig B7–B9
#   Line plots comparing municipality counts in MiDES vs. SICONFI over time.
#
# Input CSVs columns: year_siconfi, year_tce, state_siconfi, state_tce,
#                     municipalities_tce, municipalities_siconfi

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES <- c("CE", "MG", "PB", "PR", "RS", "SP")

# ---- Helper: load, standardise, filter ----

load_siconfi_csv <- function(filename,
                             filter_rs_pre2010 = TRUE,
                             filter_pb_pre2009 = TRUE) {
  dt <- fread(file.path(input, filename))

  # Use TCE (our data) year/state as the key
  setnames(dt, "year_tce",  "year",  skip_absent = TRUE)
  setnames(dt, "state_tce", "state", skip_absent = TRUE)

  dt <- dt[!is.na(municipalities_siconfi)]
  if (filter_rs_pre2010) dt <- dt[!(state == "RS" & year < 2010)]
  if (filter_pb_pre2009) dt <- dt[!(state == "PB" & year < 2009)]

  dt[state %in% STATES]
}

# ---- Helper: 3×2 dual-line comparison plot ----

make_comparison_plot <- function(dt, title_label) {
  dt[, state := factor(state, levels = STATES)]

  dt_long <- melt(dt,
                  id.vars      = c("state", "year"),
                  measure.vars = c("municipalities_tce", "municipalities_siconfi"),
                  variable.name = "source", value.name = "n_municipalities")
  dt_long[, source_label := fifelse(source == "municipalities_tce", "MiDES", "SICONFI")]

  ggplot(dt_long, aes(x = year, y = n_municipalities,
                      color = source_label, linetype = source_label)) +
    geom_line(linewidth = 0.9) +
    scale_color_manual(values = c("MiDES" = "#1A476F", "SICONFI" = "#C0392B"),
                       name = NULL) +
    scale_linetype_manual(values = c("MiDES" = "solid", "SICONFI" = "dashed"),
                          name = NULL) +
    scale_x_continuous("Year", breaks = seq(2006, 2022, by = 2)) +
    scale_y_continuous("Number of Municipalities") +
    ggtitle(title_label) +
    facet_wrap(~state, nrow = 2, ncol = 3, scales = "free_y") +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 10, y_text_size = 10, size = 11,
              legend_position = "bottom",
              axis_text_x = element_markdown(size = 10, angle = 45, hjust = 1,
                                             family = "LM Roman 10")) +
    theme(plot.title  = element_text(hjust = 0.5, size = 13, family = "LM Roman 10"),
          strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text  = element_text(size = 11, family = "LM Roman 10"))
}

# ---- Fig B7–B9 ----

ggsave(file.path(graph_output, "total_municipalities_commitment.pdf"),
       make_comparison_plot(load_siconfi_csv("data_commitment_siconfi.csv"),
                            "Commitments: MiDES vs. SICONFI"),
       width = 12, height = 7, device = cairo_pdf)

ggsave(file.path(graph_output, "total_municipalities_verification.pdf"),
       make_comparison_plot(load_siconfi_csv("data_verification_siconfi.csv"),
                            "Verifications: MiDES vs. SICONFI"),
       width = 12, height = 7, device = cairo_pdf)

ggsave(file.path(graph_output, "total_municipalities_payment.pdf"),
       make_comparison_plot(load_siconfi_csv("data_payment_siconfi.csv"),
                            "Payments: MiDES vs. SICONFI"),
       width = 12, height = 7, device = cairo_pdf)
