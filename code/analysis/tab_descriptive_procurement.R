# code/analysis/tab_descriptive_procurement.R
# Output: Tab 2 (descriptive statistics for procurement / tenders)
#
# Input CSVs (pre-downloaded by code/build/ingest_bigquery.R):
#   merge_licitacao_item.csv        — % tenders with item data
#   merge_licitacao_participante.csv — % tenders with participant data
#   licitacao_stats_uf.csv          — counts and shares by state
#   licitacao_share_valor_uf.csv    — value shares by state
#   licitacao_participante_stats.csv — avg participants/suppliers per tender
#   licitacao_participante_stats_uf.csv — participant counts by state

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("kableExtra", install = TRUE, character.only = TRUE)

STATES <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")

# ---- Load CSVs ----

dt_item  <- fread(file.path(input, "merge_licitacao_item.csv"))
dt_part  <- fread(file.path(input, "merge_licitacao_participante.csv"))
dt_stats <- fread(file.path(input, "licitacao_stats_uf.csv"))
dt_valor <- fread(file.path(input, "licitacao_share_valor_uf.csv"))
dt_part_stats  <- fread(file.path(input, "licitacao_participante_stats.csv"))
dt_part_uf     <- fread(file.path(input, "licitacao_participante_stats_uf.csv"))

# ---- Restrict to in-sample states ----

dt_item       <- dt_item[sigla_uf  %in% STATES]
dt_part       <- dt_part[sigla_uf  %in% STATES]
dt_stats      <- dt_stats[sigla_uf %in% STATES]
dt_valor      <- dt_valor[sigla_uf %in% STATES]
dt_part_uf    <- dt_part_uf[sigla_uf %in% STATES]

# ---- Build summary by state ----

# Base: distinct tenders and municipalities per state
summary <- dt_stats[, .(
  state              = sigla_uf,
  n_tenders          = total_licitacoes,
  n_municipalities   = total_municipios,
  pct_noncompetitive = 100 * share_nao_competitiva,
  pct_deserted       = 100 * share_deserta,
  pct_unsuccessful   = 100 * share_sem_resultado
)]

# % tenders with item info
item_share <- dt_item[, .(state = sigla_uf,
                           pct_with_items = 100 * n_with_item / total_licitacoes)]
summary <- merge(summary, item_share, by = "state", all.x = TRUE)

# % tenders with participant info
part_share <- dt_part[, .(state = sigla_uf,
                           pct_with_part = 100 * n_with_participante / total_licitacoes)]
summary <- merge(summary, part_share, by = "state", all.x = TRUE)

# Avg items, participants, suppliers per tender
part_avg <- dt_part_stats[, .(state = sigla_uf,
                               avg_items        = mean_itens,
                               avg_participants = mean_participantes,
                               avg_suppliers    = mean_vencedores)]
summary <- merge(summary, part_avg, by = "state", all.x = TRUE)

# Distinct participants and suppliers
part_counts <- dt_part_uf[, .(state = sigla_uf,
                               n_participants  = total_participantes,
                               n_suppliers     = total_vencedores,
                               pct_firms       = 100 * share_firmas)]
summary <- merge(summary, part_counts, by = "state", all.x = TRUE)

# Non-competitive value share
valor_nc <- dt_valor[, .(state = sigla_uf,
                          pct_nc_value = 100 * share_valor_nao_competitiva)]
summary <- merge(summary, valor_nc, by = "state", all.x = TRUE)

# State ordering
summary[, state := factor(state, levels = STATES)]
setorder(summary, state)

# ---- Add total row (weighted averages / sums) ----

total_row <- data.table(
  state              = "Total",
  n_tenders          = sum(summary$n_tenders, na.rm = TRUE),
  n_municipalities   = sum(summary$n_municipalities, na.rm = TRUE),
  pct_noncompetitive = weighted.mean(summary$pct_noncompetitive, summary$n_tenders, na.rm = TRUE),
  pct_deserted       = weighted.mean(summary$pct_deserted,       summary$n_tenders, na.rm = TRUE),
  pct_unsuccessful   = weighted.mean(summary$pct_unsuccessful,   summary$n_tenders, na.rm = TRUE),
  pct_with_items     = weighted.mean(summary$pct_with_items,     summary$n_tenders, na.rm = TRUE),
  pct_with_part      = weighted.mean(summary$pct_with_part,      summary$n_tenders, na.rm = TRUE),
  avg_items          = weighted.mean(summary$avg_items,          summary$n_tenders, na.rm = TRUE),
  avg_participants   = weighted.mean(summary$avg_participants,   summary$n_tenders, na.rm = TRUE),
  avg_suppliers      = weighted.mean(summary$avg_suppliers,      summary$n_tenders, na.rm = TRUE),
  n_participants     = sum(summary$n_participants, na.rm = TRUE),
  n_suppliers        = sum(summary$n_suppliers, na.rm = TRUE),
  pct_firms          = weighted.mean(summary$pct_firms, summary$n_suppliers, na.rm = TRUE),
  pct_nc_value       = weighted.mean(summary$pct_nc_value, summary$n_tenders, na.rm = TRUE)
)

summary_out <- rbind(summary, total_row, fill = TRUE)

# ---- Format ----

fmt_int  <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")
fmt_pct  <- function(x) sprintf("%.1f", x)
fmt_avg  <- function(x) sprintf("%.1f", x)

display <- data.frame(
  State                          = as.character(summary_out$state),
  `Tenders`                      = fmt_int(summary_out$n_tenders),
  `Municipalities`               = fmt_int(summary_out$n_municipalities),
  `With items (\\%)`             = fmt_pct(summary_out$pct_with_items),
  `With participants (\\%)`      = fmt_pct(summary_out$pct_with_part),
  `Avg items`                    = fmt_avg(summary_out$avg_items),
  `Avg participants`             = fmt_avg(summary_out$avg_participants),
  `Avg suppliers`                = fmt_avg(summary_out$avg_suppliers),
  `Non-competitive (\\%)`        = fmt_pct(summary_out$pct_noncompetitive),
  `NC value (\\%)`               = fmt_pct(summary_out$pct_nc_value),
  `Deserted (\\%)`               = fmt_pct(summary_out$pct_deserted),
  `Unsuccessful (\\%)`           = fmt_pct(summary_out$pct_unsuccessful),
  `Participants`                 = fmt_int(summary_out$n_participants),
  `Suppliers`                    = fmt_int(summary_out$n_suppliers),
  `Firms among suppliers (\\%)`  = fmt_pct(summary_out$pct_firms),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

# Save CSV
fwrite(summary_out, file.path(table_output, "descriptive_statistics_procurement.csv"))

# Save LaTeX
latex_tab <- kableExtra::kable(display, format = "latex", booktabs = TRUE,
                               escape = FALSE,
                               caption = "Descriptive Statistics: Procurement") |>
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down")) |>
  kableExtra::row_spec(nrow(display), bold = TRUE)

writeLines(latex_tab, file.path(table_output, "descriptive_statistics.tex"))
