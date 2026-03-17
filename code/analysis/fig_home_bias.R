# code/analysis/fig_home_bias.R
#
# Outputs (unweighted, from participante_cnpj.csv):
#   output/figures/Dahis Fig 7.png           — main paper Fig 7: by-state histogram
#   output/figures/home_bias_by_type_unw.png — appendix: by purchase type (unweighted)
#   output/figures/home_bias_population_unw.png — appendix: by population (unweighted)
#   output/figures/home_bias_population_scatter.png — appendix: LOESS scatter vs population
#
# Note: Fig 8 (Dahis Fig 8.png), all weighted variants, and the federal-vs-municipal
#       scatter are produced by code/analysis/fig_home_bias_federal.R.
#
# Input CSVs (Data/Raw/):
#   participante_cnpj.csv   — ano, sigla_uf, id_municipio, id_licitacao_bd, vencedor,
#                             modalidade, id_municipio_1, sigla_uf_1,
#                             data_inicio_atividade, opcao_simples, opcao_mei
#   population.csv          — ano, sigla_uf, id_municipio, populacao

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES_SAMPLE <- c("CE", "MG", "PB", "PE", "PR", "RS")

# ---- Load data ----

part <- fread(file.path(input, "participante_cnpj.csv"))
pop  <- fread(file.path(input, "population.csv"))

# ---- Construct variables ----

part[, same_municipality := as.integer(!is.na(id_municipio_1) &
                                          id_municipio_1 == id_municipio)]
part[, licitacao_discricionaria := as.integer(modalidade %in% c(8L, 10L))]

# Filter: 2014+, in-sample states, winners with valid CNPJ (14-digit id)
part <- part[ano >= 2014 & sigla_uf %in% STATES_SAMPLE & vencedor == 1]

# Deduplicate: one row per (tender, firm)
part <- unique(part, by = c("id_licitacao_bd", "id_municipio_1"), na.rm = FALSE)

# ---- Aggregate to tender municipality × year ----

agg <- part[, .(
  mean_same_mun = mean(same_municipality, na.rm = TRUE),
  discretionary = mean(licitacao_discricionaria, na.rm = TRUE)
), by = .(municipality = id_municipio, state = sigla_uf, year = ano)]

# ---- Merge population; create above/below-median flag ----

pop_2018 <- pop[ano == 2018, .(municipality = id_municipio, populacao)]
agg <- merge(agg, pop_2018, by = "municipality", all.x = TRUE)
med_pop <- median(agg$populacao, na.rm = TRUE)
agg[, pop_above_median := as.integer(populacao >= med_pop)]

# ---- Helper: two-panel histogram ----

two_panel_hist <- function(dt, group_col, labels, x_label, show_mean_line = TRUE) {
  dt <- dt[!is.na(get(group_col))]
  dt[, group_label := factor(get(group_col), levels = c(0L, 1L), labels = labels)]
  means <- dt[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = group_label]

  p <- ggplot(dt, aes(x = mean_same_mun)) +
    geom_histogram(bins = 60, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
    scale_x_continuous(x_label, limits = c(0, 1), breaks = seq(0, 1, 0.25),
                       labels = scales::percent_format(accuracy = 1)) +
    scale_y_continuous("Number of municipalities") +
    facet_wrap(~group_label, nrow = 1) +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 12, y_text_size = 12, size = 13) +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text = element_text(size = 12, family = "LM Roman 10"))

  if (show_mean_line) {
    p <- p + geom_vline(data = means, aes(xintercept = mean_val),
                        color = "#C0392B", linewidth = 0.9, linetype = "dashed")
  }
  p
}

# ---- Fig 7 (main paper): by state ----
# "Distribution of share of local suppliers across different states"

STATES_6 <- c("CE", "MG", "RS", "PB", "PR", "PE")
winners_s <- agg[state %in% STATES_6]
winners_s[, state := factor(state, levels = STATES_6)]
state_means <- winners_s[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = state]

p_state <- ggplot(winners_s, aes(x = mean_same_mun)) +
  geom_histogram(bins = 25, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(data = state_means, aes(xintercept = mean_val),
             color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
  scale_x_continuous("Share of local suppliers (winners)",
                     limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous("Number of municipalities") +
  facet_wrap(~state, nrow = 3, scales = "free_y") +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 11, y_text_size = 11, size = 12) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 12, family = "LM Roman 10"))

ggsave(file.path(graph_output, "Dahis Fig 7.png"),
       p_state, width = 8, height = 6, dpi = 300)

# ---- Appendix: by purchase type (unweighted) ----
# "Distribution of share of local suppliers, by type of purchase"

agg[, competitive := as.integer(discretionary < 0.5)]
p_type <- two_panel_hist(agg, "competitive",
                         labels  = c("Non-competitive majority", "Competitive majority"),
                         x_label = "Share of local suppliers (winners)")
ggsave(file.path(graph_output, "home_bias_by_type_unw.png"),
       p_type, width = 12, height = 5, dpi = 300)

# ---- Appendix: by population (unweighted) ----
# "Distribution of share of local suppliers, by population size"

p_pop <- two_panel_hist(agg, "pop_above_median",
                        labels  = c("Below-median population", "Above-median population"),
                        x_label = "Share of local suppliers (winners)")
ggsave(file.path(graph_output, "home_bias_population_unw.png"),
       p_pop, width = 12, height = 5, dpi = 300)

# ---- Appendix: LOESS scatter of home bias vs. population (unweighted) ----
# "Share of local suppliers - by municipality size"

pop_scatter_dt <- agg[!is.na(populacao) & populacao < 1e6]

p_scatter <- ggplot(pop_scatter_dt, aes(x = populacao, y = mean_same_mun)) +
  geom_smooth(method = "loess", se = TRUE, color = "#1A476F", fill = "#1A476F",
              alpha = 0.25, linewidth = 1.2) +
  geom_point(alpha = 0.3, size = 1, color = "#1A476F") +
  scale_x_continuous("Population (2018)", labels = scales::comma) +
  scale_y_continuous("Share of local suppliers",
                     limits = c(0, 1), labels = scales::percent_format(accuracy = 1)) +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 12, y_text_size = 12, size = 13)

ggsave(file.path(graph_output, "home_bias_population_scatter.png"),
       p_scatter, width = 10, height = 5.625, dpi = 300)

cat("  Wrote: Dahis Fig 7.png, home_bias_by_type_unw.png,",
    "home_bias_population_unw.png, home_bias_population_scatter.png\n")
