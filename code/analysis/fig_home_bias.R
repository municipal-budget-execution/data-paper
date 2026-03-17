# code/analysis/fig_home_bias.R
#
# Outputs (unweighted, from mides_2021_items_alternative_price.csv):
#   output/figures/Dahis Fig 7.png           — main paper Fig 7: by-state histogram
#   output/figures/home_bias_by_type_unw.png — appendix: by purchase type (unweighted)
#   output/figures/home_bias_population_unw.png — appendix: by population (unweighted)
#   output/figures/home_bias_population_scatter.png — appendix: LOESS scatter vs population
#
# Note: Fig 8 (Dahis Fig 8.png), all weighted variants, and the federal-vs-municipal
#       scatter are produced by code/analysis/fig_home_bias_federal.R.
#
# Input files:
#   Data/Intermediate/Transparency_Federal_2021/mides_2021_items_alternative_price.csv
#   Data/Intermediate/BigQuery/population.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

STATES_SAMPLE <- c("CE", "MG", "PB", "PE", "PR", "RS")

# ---- Load data ----

mides <- fread(file.path(intermediate,
                         "Transparency_Federal_2021/mides_2021_items_alternative_price.csv"))
pop   <- fread(file.path(bigquery, "population.csv"))

# ---- Construct variables ----

mides[, same_municipality := fcase(
  id_municipio == id_municipio_1,  1L,
  id_municipio != id_municipio_1,  0L,
  default = NA_integer_
)]
mides[, licitacao_discricionaria := as.integer(modalidade %in% c("8", "10"))]

# Dedup: one row per (tender, firm CNPJ)
mides <- unique(mides, by = c("id_licitacao_bd", "cnpj"))

# Filter: 2014+, in-sample states, winners only
mides <- mides[ano >= 2014 & sigla_uf %in% STATES_SAMPLE & vencedor == 1]

# ---- Aggregate to municipality (across all years) ----
# One observation per municipality — matches archive code structure

home_bias <- mides[, .(
  same_municipality = mean(same_municipality, na.rm = TRUE),
  discretionary     = mean(licitacao_discricionaria, na.rm = TRUE)
), by = .(municipality = id_municipio, state = sigla_uf)]

# ---- Fig 7 (main paper): by state ----
# "Distribution of share of local suppliers across different states"

STATES_6 <- c("PB", "PE", "CE", "RS", "PR", "MG")
winners_s <- home_bias[state %in% STATES_6]
state_means <- winners_s[, .(mean_val = mean(same_municipality, na.rm = TRUE)), by = state]

p_state <- ggplot(winners_s, aes(x = same_municipality)) +
  geom_histogram(aes(y = after_stat(width * density)), binwidth = 0.025,
                 fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(data = state_means, aes(xintercept = mean_val),
             color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
  geom_text(data = state_means,
            aes(x = mean_val + 0.02, label = sprintf("%.2f", mean_val)),
            y = Inf, vjust = 2, hjust = 0, color = "#C0392B", size = 3.5,
            family = "LM Roman 10") +
  scale_x_continuous("Share of same-municipality suppliers",
                     limits = c(0, 0.7)) +
  scale_y_continuous("Share", limits = c(0, 0.15)) +
  facet_wrap(~reorder(state, mean_val), nrow = 3) +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 11, y_text_size = 11, size = 12) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 12, family = "LM Roman 10"))

ggsave(file.path(graph_output, "Dahis Fig 7.png"),
       p_state, width = 8, height = 6, dpi = 300)

# ---- Appendix: by purchase type (unweighted) ----
# "Distribution of share of local suppliers, by type of purchase"

home_bias_comp <- mides[!is.na(licitacao_discricionaria), .(
  same_municipality = mean(same_municipality, na.rm = TRUE)
), by = .(municipality = id_municipio, licitacao_discricionaria)]

home_bias_comp[, `:=`(
  type_string     = fifelse(licitacao_discricionaria == 1,
                            "Non-competitive tender", "Competitive tender"),
  average_modality = mean(same_municipality, na.rm = TRUE)
), by = licitacao_discricionaria]

mean_comp <- unique(home_bias_comp[, .(type_string, average_modality)])

p_type <- ggplot(home_bias_comp, aes(x = same_municipality)) +
  geom_histogram(aes(y = after_stat(width * density)), binwidth = 0.025,
                 fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(data = mean_comp, aes(xintercept = average_modality),
             color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
  geom_text(data = mean_comp,
            aes(x = average_modality + 0.02, label = sprintf("%.2f", average_modality)),
            y = Inf, vjust = 2, hjust = 0, color = "#C0392B", size = 3.5,
            family = "LM Roman 10") +
  scale_x_continuous("Share of same-municipality suppliers", limits = c(0, 1)) +
  scale_y_continuous("Share") +
  facet_wrap(~type_string, nrow = 2) +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 12, y_text_size = 12, size = 13) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 12, family = "LM Roman 10"))

ggsave(file.path(graph_output, "home_bias_by_type_unw.png"),
       p_type, width = 12, height = 5, dpi = 300)

# ---- Appendix: by population (unweighted) ----
# "Distribution of share of local suppliers, by population size"

pop_2018 <- pop[ano == 2018, .(municipality = id_municipio, populacao)]
pop_2018[, populacao := as.numeric(populacao)]
med_pop <- median(pop_2018$populacao, na.rm = TRUE)

home_bias_pop <- merge(home_bias, pop_2018, by = "municipality", all.x = TRUE)
home_bias_pop[, pop_above_median := fifelse(populacao > med_pop, 1L, 0L, na = NA_integer_)]
home_bias_pop[, `:=`(
  type_string        = fifelse(pop_above_median == 1,
                               "Population Above Median", "Population Below Median"),
  average_population = mean(same_municipality, na.rm = TRUE)
), by = pop_above_median]

venc_pop <- home_bias_pop[!is.na(pop_above_median)]
mean_pop  <- unique(venc_pop[, .(type_string, average_population)])

p_pop <- ggplot(venc_pop, aes(x = same_municipality)) +
  geom_histogram(aes(y = after_stat(width * density)), binwidth = 0.025,
                 fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(data = mean_pop, aes(xintercept = average_population),
             color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
  geom_text(data = mean_pop,
            aes(x = average_population + 0.02, label = sprintf("%.2f", average_population)),
            y = Inf, vjust = 2, hjust = 0, color = "#C0392B", size = 3.5,
            family = "LM Roman 10") +
  scale_x_continuous("Share of same-municipality suppliers", limits = c(0, 1)) +
  scale_y_continuous("Share") +
  facet_wrap(~type_string, nrow = 2) +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line(),
            x_text_size = 12, y_text_size = 12, size = 13) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 12, family = "LM Roman 10"))

ggsave(file.path(graph_output, "home_bias_population_unw.png"),
       p_pop, width = 12, height = 5, dpi = 300)

# ---- Appendix: LOESS scatter of home bias vs. population (unweighted) ----

pop_scatter_dt <- home_bias_pop[!is.na(populacao) & populacao < 1e6]

p_scatter <- ggplot(pop_scatter_dt, aes(x = populacao, y = same_municipality)) +
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
