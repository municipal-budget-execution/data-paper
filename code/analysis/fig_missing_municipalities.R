# code/analysis/fig_missing_municipalities.R
# Outputs: Fig B5–B6
#   Line plots of % missing municipalities over time by state.
#
# Input CSVs use: ano (year), sigla_uf (state), distinct_municipalities

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")

# Total municipalities per state (IBGE reference)
total_mun <- data.table(
  state = c("CE", "MG", "PB", "PE", "PR", "RS", "SP"),
  total = c(184L, 853L, 223L, 185L, 399L, 497L, 645L)
)

# ---- Helper: load, standardise, compute % missing ----

load_count_csv <- function(filename,
                           filter_rs_pre2010 = FALSE,
                           filter_pb_pre2009 = FALSE) {
  dt <- fread(file.path(input, filename))
  # Standardise column names
  setnames(dt, "ano",      "year",  skip_absent = TRUE)
  setnames(dt, "sigla_uf", "state", skip_absent = TRUE)

  dt <- merge(dt, total_mun, by = "state")
  dt[, perc_missing := 100 * (total - distinct_municipalities) / total]

  if (filter_rs_pre2010) dt <- dt[!(state == "RS" & year < 2010)]
  if (filter_pb_pre2009) dt <- dt[!(state == "PB" & year < 2009)]

  dt[state %in% STATES]
}

# ---- Helper: stacked line plots (one line per state) ----

make_missing_plot <- function(dt_list, panel_titles) {
  plot_list <- lapply(seq_along(dt_list), function(i) {
    dt <- dt_list[[i]]
    dt[, state := factor(state, levels = STATES)]

    ggplot(dt, aes(x = year, y = perc_missing, color = state, group = state)) +
      geom_line(linewidth = 0.8) +
      scale_color_brewer(palette = "Dark2", name = "State") +
      scale_x_continuous("Year", breaks = seq(2006, 2022, by = 2)) +
      scale_y_continuous("% Missing Municipalities", limits = c(0, NA)) +
      ggtitle(panel_titles[[i]]) +
      set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
                x_text_size = 10, y_text_size = 10, size = 11,
                legend_position = if (i == length(dt_list)) "right" else "none",
                axis_text_x = element_markdown(size = 10, angle = 45, hjust = 1,
                                               family = "LM Roman 10")) +
      theme(plot.title  = element_text(hjust = 0.5, size = 12, family = "LM Roman 10"))
  })

  ggpubr::ggarrange(plotlist = plot_list, ncol = 1, nrow = length(plot_list),
                    common.legend = TRUE, legend = "right")
}

# ---- Fig B5: Procurement ----

p_proc <- make_missing_plot(
  list(load_count_csv("count_mun_lic.csv"),
       load_count_csv("count_mun_lic_item.csv"),
       load_count_csv("count_mun_lic_part.csv")),
  panel_titles = c("Tender", "Tender-Item", "Tender-Participant")
)
ggsave(file.path(graph_output, "missing_municipalities_procurement.pdf"),
       p_proc, width = 8, height = 10, device = cairo_pdf)

# ---- Fig B6: Budget execution ----

p_exec <- make_missing_plot(
  list(load_count_csv("count_mun_empenho.csv",
                      filter_rs_pre2010 = TRUE, filter_pb_pre2009 = TRUE),
       load_count_csv("count_mun_liq.csv",
                      filter_rs_pre2010 = TRUE, filter_pb_pre2009 = TRUE),
       load_count_csv("count_mun_pag.csv",
                      filter_rs_pre2010 = TRUE, filter_pb_pre2009 = TRUE)),
  panel_titles = c("Commitment", "Verification", "Payment")
)
ggsave(file.path(graph_output, "missing_municipalities_budget_sample.pdf"),
       p_exec, width = 8, height = 10, device = cairo_pdf)
