# code/analysis/fig_home_bias.R
# Outputs: Fig 6–8
#
# Input CSVs:
#   participante_cnpj.csv   columns: ano, sigla_uf (tender state), id_municipio (tender mun),
#                                    id_licitacao_bd, vencedor, modalidade,
#                                    id_municipio_1 (firm mun), sigla_uf_1 (firm state),
#                                    data_inicio_atividade, opcao_simples, opcao_mei
#   population.csv          columns: ano, sigla_uf, id_municipio, populacao

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES_SAMPLE <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")

# ---- Load data ----

part <- fread(file.path(input, "participante_cnpj.csv"))
pop  <- fread(file.path(input, "population.csv"))

# ---- Construct variables ----
# id_municipio  = tender municipality; id_municipio_1 = firm municipality
# sigla_uf      = tender state;        sigla_uf_1     = firm state

part[, same_municipality := as.integer(!is.na(id_municipio_1) &
                                          id_municipio_1 == id_municipio)]
part[, same_state        := as.integer(!is.na(sigla_uf_1) &
                                          sigla_uf_1 == sigla_uf)]
part[, licitacao_discricionaria := as.integer(modalidade %in% c(8, 10))]

# Filter to 2014+, in-sample states, winners of competitive tenders for bias analysis
part <- part[ano >= 2014 & sigla_uf %in% STATES_SAMPLE]

# Deduplicate: one row per (tender, firm)
part <- unique(part, by = c("id_licitacao_bd", "id_municipio_1"), na.rm = FALSE)

# ---- Aggregate to tender municipality × year × winner ----

agg <- part[, .(
  mean_same_mun = mean(same_municipality, na.rm = TRUE),
  discretionary = mean(licitacao_discricionaria, na.rm = TRUE)
), by = .(municipality = id_municipio, state = sigla_uf, year = ano, winner = vencedor)]

# ---- Merge population; create above/below-median flag ----

pop_2018 <- pop[ano == 2018, .(municipality = id_municipio, populacao)]
agg <- merge(agg, pop_2018, by = "municipality", all.x = TRUE)
med_pop <- median(agg$populacao, na.rm = TRUE)
agg[, pop_above_median := as.integer(populacao >= med_pop)]

winners <- agg[winner == 1]

# ---- Helper: two-panel histogram ----

two_panel_hist <- function(dt, group_col, labels, x_label) {
  dt <- dt[!is.na(get(group_col))]
  dt[, group_label := factor(get(group_col), levels = c(0, 1), labels = labels)]
  means <- dt[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = group_label]

  ggplot(dt, aes(x = mean_same_mun)) +
    geom_histogram(bins = 60, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
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

winners[, competitive := as.integer(discretionary < 0.5)]
p_comp <- two_panel_hist(winners, "competitive",
                         labels  = c("Non-competitive majority", "Competitive majority"),
                         x_label = "Share of local suppliers (winners)")
ggsave(file.path(graph_output, "home_bias_all.pdf"),
       p_comp, width = 12, height = 5, device = cairo_pdf)

# ---- Fig 7: Population ----

p_pop <- two_panel_hist(winners, "pop_above_median",
                        labels  = c("Below-median population", "Above-median population"),
                        x_label = "Share of local suppliers (winners)")
ggsave(file.path(graph_output, "home_bias_population.pdf"),
       p_pop, width = 12, height = 5, device = cairo_pdf)

# ---- Fig 8: By state (6 in-sample states visible in paper) ----

STATES_6 <- c("CE", "MG", "RS", "PB", "PR", "SP")
winners_s <- winners[state %in% STATES_6]
winners_s[, state := factor(state, levels = STATES_6)]
state_means <- winners_s[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = state]

p_state <- ggplot(winners_s, aes(x = mean_same_mun)) +
  geom_histogram(bins = 50, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(data = state_means, aes(xintercept = mean_val),
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
