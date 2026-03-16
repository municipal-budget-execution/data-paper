# code/analysis/fig_home_bias.R
# Outputs: Fig 6–8
#   Histograms of home bias (share of local suppliers) by:
#   - competitive vs. non-competitive tenders (Fig 6)
#   - above- vs. below-median population municipalities (Fig 7)
#   - by state (Fig 8)
#
# Input CSVs (pre-downloaded by code/build/ingest_bigquery.R):
#   participante_cnpj.csv   — tender participants merged with firm characteristics
#   population.csv          — municipality population (2018)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES_SAMPLE <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")

# ---- Load data ----

part <- fread(file.path(input, "participante_cnpj.csv"))
pop  <- fread(file.path(input, "population.csv"))

# ---- Construct variables ----

# same_municipality: firm's municipality == tender's municipality
# Columns expected: id_municipio (firm), id_municipio_lic (tender), sigla_uf, sigla_uf_lic, ano, vencedor, modalidade
part[, same_municipality := as.integer(id_municipio == id_municipio_lic)]
part[, same_state        := as.integer(sigla_uf     == sigla_uf_lic)]
part[, licitacao_discricionaria := as.integer(modalidade %in% c(8, 10))]

# Restrict to 2014 onwards
part <- part[ano >= 2014]

# Keep only in-sample states
part <- part[sigla_uf_lic %in% STATES_SAMPLE]

# Deduplicate: one row per (tender, firm)
part <- unique(part, by = c("id_licitacao_bd", "id_municipio"))

# ---- Aggregate to municipality × year × winner level ----

agg <- part[, .(
  mean_same_mun   = mean(same_municipality, na.rm = TRUE),
  discretionary   = mean(licitacao_discricionaria, na.rm = TRUE)
), by = .(id_municipio_lic, sigla_uf_lic, ano, vencedor)]

setnames(agg, c("municipality", "state", "year", "winner"))

# ---- Merge population; create above/below median flag ----

pop_2018 <- pop[year == 2018, .(municipality = id_municipio, population)]
agg <- merge(agg, pop_2018, by = "municipality", all.x = TRUE)

med_pop <- median(agg$population, na.rm = TRUE)
agg[, pop_above_median := as.integer(population >= med_pop)]

# Winners only for home bias plots
winners <- agg[winner == 1]

# ---- Helper: two-panel histogram with means ----

two_panel_hist <- function(dt, group_col, labels, x_label) {
  dt <- dt[!is.na(get(group_col))]
  dt[, group_label := factor(get(group_col), levels = c(0, 1), labels = labels)]

  means <- dt[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = group_label]

  ggplot(dt, aes(x = mean_same_mun)) +
    geom_histogram(bins = 60, fill = "#1A476F", color = "#0D3446", linewidth = 0.3, alpha = 0.9) +
    geom_vline(data = means, aes(xintercept = mean_val),
               color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
    scale_x_continuous(x_label, limits = c(0, 1), breaks = seq(0, 1, 0.25),
                       labels = scales::percent_format(accuracy = 1)) +
    scale_y_continuous("Number of municipalities") +
    facet_wrap(~group_label, nrow = 1) +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
              x_text_size = 12, y_text_size = 12, size = 13) +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text = element_text(size = 12, family = "LM Roman 10"))
}

# ---- Fig 6: Competitive vs. non-competitive ----

winners[, competitive := as.integer(discretionary < 0.5)]   # majority competitive
p_comp <- two_panel_hist(winners, "competitive",
                         labels    = c("Non-competitive majority", "Competitive majority"),
                         x_label   = "Share of local suppliers (winners)")
ggsave(file.path(graph_output, "home_bias_all.pdf"),
       p_comp, width = 12, height = 5, device = cairo_pdf)

# ---- Fig 7: Below- vs. above-median population ----

p_pop <- two_panel_hist(winners, "pop_above_median",
                        labels  = c("Below-median population", "Above-median population"),
                        x_label = "Share of local suppliers (winners)")
ggsave(file.path(graph_output, "home_bias_population.pdf"),
       p_pop, width = 12, height = 5, device = cairo_pdf)

# ---- Fig 8: By state ----

winners_states <- winners[state %in% STATES_SAMPLE]
winners_states[, state := factor(state, levels = STATES_SAMPLE)]

state_means <- winners_states[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = state]

# Use only 6 states visible in the paper (exclude PE for map reasons, or use all 7)
p_state <- ggplot(winners_states[state %in% c("CE", "MG", "RS", "PB", "PR", "SP")],
                  aes(x = mean_same_mun)) +
  geom_histogram(bins = 50, fill = "#1A476F", color = "#0D3446", linewidth = 0.3, alpha = 0.9) +
  geom_vline(data = state_means[state %in% c("CE", "MG", "RS", "PB", "PR", "SP")],
             aes(xintercept = mean_val),
             color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
  scale_x_continuous("Share of local suppliers (winners)",
                     limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous("Number of municipalities") +
  facet_wrap(~state, nrow = 2, scales = "free_y") +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 11, y_text_size = 11, size = 12) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 12, family = "LM Roman 10"))

ggsave(file.path(graph_output, "home_bias_by_state.pdf"),
       p_state, width = 12, height = 7, device = cairo_pdf)
