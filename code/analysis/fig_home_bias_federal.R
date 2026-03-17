# code/analysis/fig_home_bias_federal.R
#
# Outputs (require Data/Intermediate — built by code/build/API_ComprasDados/BuildHomeBiasFederalEntities.R):
#   output/figures/Dahis Fig 8.png                       — main paper Fig 8: federal vs municipal scatter
#   output/figures/scatter_federal_localpurchase_weighted.png — appendix
#   output/figures/home_bias_by_state_weighted.png        — appendix
#   output/figures/home_bias_by_type_weighted.png         — appendix
#   output/figures/home_bias_population_weighted.png      — appendix
#   output/figures/home_bias_population_scatter_both.png  — appendix
#   output/figures/regression_home_bias.tex               — main paper Tab 5 (mun vs federal)
#   output/figures/regression_home_bias_weighted.tex      — appendix
#   output/figures/reg_home_bias_correlates_weighted.tex  — appendix
#
# Data inputs (Data/Intermediate/):
#   Transparency_Federal_2021/licitacoes_2021.rds
#   Transparency_Federal_2021/licitacoes_items_2021.rds
#   Transparency_Federal_2021/suppliers_munic_federal.csv
#   mides_2021_items_alternative_price.csv
# Data inputs (Data/Raw/):
#   RELATORIO_DTB_BRASIL_2024_MUNICIPIOS.xls
#   full_budget_execution_index.csv   (for GDP and population in weighted correlates reg)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

pacman::p_load("fixest", "ggrepel", "DescTools", "janitor", "stringi", "readxl",
               install = TRUE, character.only = TRUE)

in_dir <- file.path(intermediate, "Transparency_Federal_2021")

# ---- Load federal tender-item data ----

data_lic  <- readRDS(file.path(in_dir, "licitacoes_2021.rds"))        |> setDT()
data_item <- readRDS(file.path(in_dir, "licitacoes_items_2021.rds"))  |> setDT()

STATES_SAMPLE <- c("RS", "PR", "PE", "MG", "PB", "CE")

data_item_sample <- data_item |>
  inner_join(
    data_lic[uf %in% STATES_SAMPLE,
             .(municipio = first(municipio), uf = first(uf)),
             by = codigo_ug],
    by = "codigo_ug"
  ) |> setDT()

# ---- Recover supplier municipality codes ----

unique_winners_cnpj_muni <- fread(file.path(in_dir, "suppliers_munic_federal.csv"))

data_item_sample <- data_item_sample |>
  left_join(
    unique_winners_cnpj_muni |>
      mutate(codigo_vencedor = as.character(codigo_vencedor)) |>
      rename(id_municipio_winner = id_municipio, sigla_uf_winner = sigla_uf) |>
      select(codigo_vencedor, id_municipio_winner, sigla_uf_winner),
    by = "codigo_vencedor"
  ) |> setDT()

# Map municipality names → IBGE codes
munic_code <- readxl::read_xls(file.path(input, "RELATORIO_DTB_BRASIL_2024_MUNICIPIOS.xls")) |>
  clean_names() |>
  select(uf, codigo_municipio_completo, nome_municipio) |>
  mutate(municipio = str_to_upper(stri_trans_general(nome_municipio, "Latin-ASCII")))

uf_to_code <- c(RS = 43, PE = 26, PR = 41, CE = 23, PB = 25, MG = 31)

data_item_sample <- data_item_sample |>
  mutate(uf_code = as.character(uf_to_code[uf])) |>
  left_join(munic_code |>
              select(municipio, uf, codigo_municipio_completo) |>
              rename(uf_code = uf),
            by = c("municipio", "uf_code")) |>
  mutate(
    codigo_municipio_completo = ifelse(
      municipio == "SANTANA DO LIVRAMENTO", 4317103L, codigo_municipio_completo),
    same_municipality = case_when(
      codigo_municipio_completo == id_municipio_winner ~ 1,
      codigo_municipio_completo != id_municipio_winner ~ 0,
      is.na(id_municipio_winner) ~ NA_real_),
    valor_item_w = DescTools::Winsorize(valor_item,
                     val = quantile(valor_item, probs = c(0, .99), na.rm = TRUE))
  ) |> setDT()

# ---- Load MiDES item data ----

participante_cnpj <- fread(file.path(in_dir, "mides_2021_items_alternative_price.csv"))
participante_cnpj <- participante_cnpj[ano == 2021 & vencedor == 1] |>
  mutate(
    same_municipality = case_when(
      id_municipio == id_municipio_1 ~ 1,
      id_municipio != id_municipio_1 ~ 0,
      is.na(id_municipio_1) ~ NA_real_),
    sum_item_value_w = DescTools::Winsorize(sum_item_value,
                         val = quantile(sum_item_value, probs = c(0, .99), na.rm = TRUE))
  ) |> setDT()

# ---- Municipality-level shares (federal and MiDES) ----

municipality_share <- data_item_sample[
  !is.na(id_municipio_winner),
  .(share_local_federal   = mean(same_municipality, na.rm = TRUE),
    share_local_federal_w = weighted.mean(same_municipality,
                              w = coalesce(valor_item_w, 0), na.rm = TRUE),
    number_federal = .N,
    total_federal  = sum(valor_item_w)),
  by = .(municipio, codigo_municipio_completo)
] |>
  mutate(id_municipio = as.integer(codigo_municipio_completo)) |>
  inner_join(
    participante_cnpj[!is.na(id_municipio_1),
      .(share_local_mides   = mean(same_municipality, na.rm = TRUE),
        share_local_mides_w = weighted.mean(same_municipality,
                                w = coalesce(sum_item_value_w, 0), na.rm = TRUE),
        number_mides = .N,
        total_mides  = sum(coalesce(sum_item_value_w, 0))),
      by = id_municipio],
    by = "id_municipio"
  ) |>
  mutate(number_total = number_federal + number_mides,
         value_total  = total_federal  + total_mides) |>
  setDT()

# ---- Fig 8 (main paper): scatter federal vs. municipal, unweighted ----

highlights <- c("PORTO ALEGRE", "RECIFE", "CURITIBA", "BELO HORIZONTE",
                "FORTALEZA", "JOAO PESSOA")

p_scatter_unw <- municipality_share[number_federal >= 10 & number_mides >= 10] |>
  mutate(highlight = ifelse(municipio %in% highlights, "Highlight", "Other")) |>
  ggplot(aes(x = share_local_mides, y = share_local_federal)) +
  geom_point(aes(size = value_total, color = highlight), alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_text_repel(
    data = municipality_share[municipio %in% highlights],
    aes(label = municipio), size = 2.5, color = "#E74C3C", max.overlaps = 10) +
  scale_color_manual(values = c("Highlight" = "#E74C3C", "Other" = "#2C3E50")) +
  labs(x = "Share of Local Suppliers (MiDES)", y = "Share of Local Suppliers (Federal)") +
  theme_classic(base_size = 14) +
  theme(axis.title = element_text(size = 14, face = "bold"),
        axis.text  = element_text(size = 13),
        legend.position = "none")

ggsave(file.path(graph_output, "Dahis Fig 8.png"),
       p_scatter_unw, width = 10, height = 5.625, units = "in", dpi = 300)

# ---- Appendix: scatter federal vs. municipal, weighted ----

p_scatter_w <- municipality_share[number_federal >= 10 & number_mides >= 10] |>
  mutate(highlight = ifelse(municipio %in% highlights, "Highlight", "Other")) |>
  ggplot(aes(x = share_local_mides_w, y = share_local_federal_w)) +
  geom_point(aes(size = value_total, color = highlight), alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_text_repel(
    data = municipality_share[municipio %in% highlights],
    aes(label = municipio), size = 2.5, color = "#E74C3C", max.overlaps = 10) +
  scale_color_manual(values = c("Highlight" = "#E74C3C", "Other" = "#2C3E50")) +
  labs(x = "Share of Local Spending (MiDES)", y = "Share of Local Spending (Federal)") +
  theme_classic(base_size = 14) +
  theme(axis.title = element_text(size = 14, face = "bold"),
        axis.text  = element_text(size = 13),
        legend.position = "none")

ggsave(file.path(graph_output, "scatter_federal_localpurchase_weighted.png"),
       p_scatter_w, width = 10, height = 5.625, units = "in", dpi = 300)

# ---- Appendix: weighted histogram figures (exclude PB and PE — no item prices) ----

STATES_WEIGHTED <- c("CE", "MG", "PR", "RS")

part_w <- participante_cnpj[sigla_uf %in% STATES_WEIGHTED]
part_w <- part_w[ano >= 2014]
part_w <- unique(part_w, by = c("id_licitacao_bd", "id_municipio_1"), na.rm = FALSE)

# Aggregate to municipality
pop <- fread(file.path(bigquery, "population.csv"))
pop_2018 <- pop[ano == 2018, .(municipality = id_municipio, populacao)]

agg_w <- part_w[, .(
  mean_same_mun_w = weighted.mean(same_municipality,
                      w = coalesce(sum_item_value_w, 0), na.rm = TRUE),
  discretionary_w = weighted.mean(modalidade %in% c(8L, 10L),
                      w = coalesce(sum_item_value_w, 0), na.rm = TRUE),
  .N
), by = .(municipality = id_municipio, state = sigla_uf)]

setnames(agg_w, "mean_same_mun_w", "mean_same_mun")
agg_w <- merge(agg_w, pop_2018, by = "municipality", all.x = TRUE)
med_pop_w <- median(agg_w$populacao, na.rm = TRUE)
agg_w[, pop_above_median := as.integer(populacao >= med_pop_w)]
agg_w[, competitive_w    := as.integer(discretionary_w < 0.5)]

# Helper for weighted histograms
two_panel_hist_w <- function(dt, group_col, labels, x_label) {
  dt2 <- dt[!is.na(get(group_col))]
  dt2[, group_label := factor(get(group_col), levels = c(0L, 1L), labels = labels)]
  means2 <- dt2[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = group_label]

  ggplot(dt2, aes(x = mean_same_mun)) +
    geom_histogram(bins = 60, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
    geom_vline(data = means2, aes(xintercept = mean_val),
               color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
    scale_x_continuous(x_label, limits = c(0, 1), breaks = seq(0, 1, 0.25),
                       labels = scales::percent_format(accuracy = 1)) +
    scale_y_continuous("Number of municipalities") +
    facet_wrap(~group_label, nrow = 1) +
    theme_classic(base_size = 13) +
    theme(strip.background = element_rect(fill = "gray90", colour = "black"),
          strip.text = element_text(size = 12))
}

# By type (weighted)
p_type_w <- two_panel_hist_w(agg_w, "competitive_w",
  labels  = c("Non-competitive majority", "Competitive majority"),
  x_label = "Share of local spending (winners)")
ggsave(file.path(graph_output, "home_bias_by_type_weighted.png"),
       p_type_w, width = 12, height = 5, dpi = 300)

# By population (weighted)
p_pop_w <- two_panel_hist_w(agg_w, "pop_above_median",
  labels  = c("Below-median population", "Above-median population"),
  x_label = "Share of local spending (winners)")
ggsave(file.path(graph_output, "home_bias_population_weighted.png"),
       p_pop_w, width = 12, height = 5, dpi = 300)

# By state (weighted)
state_means_w <- agg_w[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = state]
STATES_4 <- c("CE", "MG", "PR", "RS")
agg_w_s <- agg_w[state %in% STATES_4]
agg_w_s[, state := factor(state, levels = STATES_4)]
state_means_w4 <- agg_w_s[, .(mean_val = mean(mean_same_mun, na.rm = TRUE)), by = state]

p_state_w <- ggplot(agg_w_s, aes(x = mean_same_mun)) +
  geom_histogram(bins = 50, fill = "#1A476F", color = "#0D3446", linewidth = 0.3) +
  geom_vline(data = state_means_w4, aes(xintercept = mean_val),
             color = "#C0392B", linewidth = 0.9, linetype = "dashed") +
  scale_x_continuous("Share of local spending (winners)",
                     limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = scales::percent_format(accuracy = 1)) +
  scale_y_continuous("Number of municipalities") +
  facet_wrap(~state, nrow = 2, scales = "free_y") +
  theme_classic(base_size = 12) +
  theme(strip.background = element_rect(fill = "gray90", colour = "black"),
        strip.text = element_text(size = 12))

ggsave(file.path(graph_output, "home_bias_by_state_weighted.png"),
       p_state_w, width = 12, height = 7, dpi = 300)

# LOESS scatter: both unweighted and weighted on same plot
pop_scatter_both <- agg_w[!is.na(populacao) & populacao < 1e6]

p_scatter_both <- ggplot(pop_scatter_both,
                         aes(x = populacao, y = mean_same_mun)) +
  geom_smooth(method = "loess", se = TRUE, color = "#1A476F", fill = "#1A476F",
              alpha = 0.25, linewidth = 1.2, aes(linetype = "Count")) +
  scale_x_continuous("Population (2018)", labels = scales::comma) +
  scale_y_continuous("Share of local spending",
                     limits = c(0, 1), labels = scales::percent_format(accuracy = 1)) +
  theme_classic(base_size = 13)

ggsave(file.path(graph_output, "home_bias_population_scatter_both.png"),
       p_scatter_both, width = 10, height = 5.625, dpi = 300)

# ---- Regression tables ----

# Build combined municipal + federal dataset
dt1 <- participante_cnpj |>
  mutate(
    municipal      = 1L,
    modality_group = case_when(
      modalidade %in% c(4L, 5L, 6L) ~ "Auction",
      modalidade == 8L               ~ "Waiver",
      modalidade == 10L              ~ "Direct Contracting",
      .default                       = "Other")
  ) |>
  select(id_municipio, sigla_uf, modality_group, same_municipality,
         sum_item_value_w, municipal) |>
  setDT()

dt2 <- data_item_sample |>
  mutate(
    municipal      = 0L,
    modality_group = case_when(
      codigo_modalidade_compra %in% c(9999L, 5L) ~ "Auction",
      codigo_modalidade_compra == 8L              ~ "Waiver",
      codigo_modalidade_compra == 7L              ~ "Direct Contracting",
      .default                                    = "Other")
  ) |>
  select(codigo_municipio_completo, uf_code, modality_group, same_municipality,
         valor_item_w, municipal) |>
  rename(id_municipio = codigo_municipio_completo,
         sigla_uf     = uf_code,
         sum_item_value_w = valor_item_w) |>
  setDT()

local_reg <- rbindlist(list(dt1, dt2)) |>
  group_by(id_municipio, municipal) |>
  mutate(number = n()) |>
  filter(number >= 50) |>
  setDT()

fixest::setFixest_etable(digits.stats = 2)

dict_fed <- c(
  "same_municipality" = "Local Supplier",
  "municipal"         = "Municipal buyer",
  "modality_group"    = "Modality",
  "id_municipio"      = "Municipality"
)

# Unweighted
m_fed1 <- feols(same_municipality ~ municipal,
                data = local_reg, cluster = ~id_municipio^municipal)
m_fed2 <- feols(same_municipality ~ municipal | modality_group + id_municipio,
                data = local_reg, cluster = ~id_municipio^municipal)

fixest::etable(m_fed1, m_fed2, tex = TRUE,
               dict    = dict_fed,
               fitstat = c("n", "my", "rmse", "r2", "ar2"),
               digits  = 3,
               file    = file.path(table_output, "regression_home_bias.tex"))

# Weighted
m_fed1_w <- feols(same_municipality ~ municipal,
                  data = local_reg,
                  weights = ~pmax(sum_item_value_w, 0),
                  cluster = ~id_municipio^municipal)
m_fed2_w <- feols(same_municipality ~ municipal | modality_group + id_municipio,
                  data = local_reg,
                  weights = ~pmax(sum_item_value_w, 0),
                  cluster = ~id_municipio^municipal)

fixest::etable(m_fed1_w, m_fed2_w, tex = TRUE,
               dict    = c("same_municipality" = "Share Local Purchases",
                           "municipal" = "Municipal buyer",
                           "modality_group" = "Modality",
                           "id_municipio" = "Municipality"),
               fitstat = c("n", "r2", "my"),
               digits  = 3,
               file    = file.path(table_output, "regression_home_bias_weighted.tex"))

# ---- Weighted correlates regression (reg_home_bias_correlates_weighted.tex) ----
# Items-level data (excludes PB, PE); dep var = same_municipality; unit = tender item

# GDP/population from 2020 (latest available year in full_budget_execution_index.csv)
mun_char <- fread(file.path(bigquery, "full_budget_execution_index.csv"),
                  select = c("municipality", "state", "year", "gdp", "population"),
                  showProgress = FALSE)[year == 2020, .(municipality, state, gdp, population)]

part_corr <- participante_cnpj[sigla_uf %in% STATES_WEIGHTED & vencedor == 1]
setnames(part_corr, c("id_municipio", "sigla_uf", "ano"),
                    c("municipality",  "state",     "year"))
part_corr[, non_competitive := as.integer(modalidade %in% c(8L, 10L))]
part_corr <- merge(part_corr, mun_char, by = c("municipality", "state"), all.x = TRUE)
part_corr <- part_corr[!is.na(gdp) & !is.na(population) & gdp > 0 & population > 0 &
                         !is.na(sum_item_value_w) & sum_item_value_w > 0]

# Data is all 2021 so year FE is not identified; use state FE only
mw1 <- feols(same_municipality ~ log(gdp) + log(population) + non_competitive,
             data = part_corr, weights = ~sum_item_value_w, cluster = ~municipality)
mw2 <- feols(same_municipality ~ log(gdp) + log(population) + non_competitive | state,
             data = part_corr, weights = ~sum_item_value_w, cluster = ~municipality)

dict_corr <- c(
  "same_municipality" = "Dummy Local Supplier",
  "log(gdp)"          = "ln(GDP)",
  "log(population)"   = "ln(Population)",
  "non_competitive"   = "Non-Competitive Tenders"
)

tbl_w_raw <- fixest::etable(mw1, mw2,
  fitstat   = c("n", "my", "rmse", "r2", "ar2"),
  digits    = 3, tex = TRUE, dict = dict_corr,
  drop      = "Constant",
  style.tex = style.tex(
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
    notes.intro = ""))

dep_idx <- grep("Dependent Variable", tbl_w_raw)
if (length(dep_idx) > 0) {
  tbl_w_raw <- c(tbl_w_raw[seq_len(dep_idx)],
                 "   \\cmidrule(lr){2-3}",
                 tbl_w_raw[(dep_idx + 1L):length(tbl_w_raw)])
}
fs_idx <- grep("Fit statistics", tbl_w_raw)

fe_block_w <- c(
  "   \\midrule",
  "   \\emph{Fixed-effects}\\\\",
  "   State &  & Yes \\\\  "
)

tbl_w_out <- c(
  tbl_w_raw[seq_len(fs_idx - 2L)],
  fe_block_w,
  tbl_w_raw[(fs_idx - 1L):length(tbl_w_raw)]
)
writeLines(tbl_w_out, file.path(table_output, "reg_home_bias_correlates_weighted.tex"))

cat("  Wrote all fig_home_bias_federal outputs.\n")
