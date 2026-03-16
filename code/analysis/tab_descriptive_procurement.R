# code/analysis/tab_descriptive_procurement.R
# Output: Tab 2 (descriptive statistics for procurement)
#
# Input CSVs and their actual columns:
#   licitacao_stats_uf.csv              sigla_uf, non_competitive_tender, deserted_tender, unsuccessful_tender
#   licitacao_share_valor_uf.csv        sigla_uf, total_valor_corrigido, non_competitive_share_valor_corrigido
#   merge_licitacao_item.csv            ano, id_municipio, sigla_uf, id_licitacao_bd, total_itens, join_type
#   merge_licitacao_participante.csv    ano, id_municipio, sigla_uf, id_licitacao_bd, join_type
#   licitacao_participante_stats.csv    sigla_uf, id_municipio, id_licitacao_bd, participantes_distintos, vencedores_distintos
#   licitacao_participante_stats_uf.csv sigla_uf, participantes_distintos, vencedores_distintos, firmas, firmas_vencedoras

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("kableExtra", install = TRUE, character.only = TRUE)

STATES <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")

# ---- Load CSVs ----

dt_stats    <- fread(file.path(input, "licitacao_stats_uf.csv"))
dt_valor    <- fread(file.path(input, "licitacao_share_valor_uf.csv"))
dt_item     <- fread(file.path(input, "merge_licitacao_item.csv"))
dt_part     <- fread(file.path(input, "merge_licitacao_participante.csv"))
dt_part_st  <- fread(file.path(input, "licitacao_participante_stats.csv"))
dt_part_uf  <- fread(file.path(input, "licitacao_participante_stats_uf.csv"))

# Filter to in-sample states
for (dt in list(dt_stats, dt_valor, dt_item, dt_part, dt_part_st, dt_part_uf)) {
  dt <- dt[sigla_uf %in% STATES]
}
dt_stats   <- dt_stats[sigla_uf %in% STATES]
dt_valor   <- dt_valor[sigla_uf %in% STATES]
dt_item    <- dt_item[sigla_uf %in% STATES]
dt_part    <- dt_part[sigla_uf %in% STATES]
dt_part_st <- dt_part_st[sigla_uf %in% STATES]
dt_part_uf <- dt_part_uf[sigla_uf %in% STATES]

# ---- Compute statistics by state ----

# Total tenders and municipalities: from item-join file (one row per tender)
total_tenders <- dt_item[, .(
  n_tenders        = .N,
  n_municipalities = uniqueN(id_municipio)
), by = sigla_uf]

# % tenders with item data (join_type == "BOTH" and total_itens is not NA)
with_items <- dt_item[, .(
  pct_with_items = 100 * mean(join_type == "BOTH" & !is.na(total_itens))
), by = sigla_uf]

# Average items per tender (among those with items)
avg_items <- dt_item[join_type == "BOTH" & !is.na(total_itens),
                     .(avg_items = mean(total_itens, na.rm = TRUE)),
                     by = sigla_uf]

# % tenders with participant data
with_part <- dt_part[, .(
  pct_with_part = 100 * mean(join_type == "BOTH")
), by = sigla_uf]

# Average participants and suppliers per tender (from per-tender stats)
avg_part <- dt_part_st[, .(
  avg_participants = mean(participantes_distintos, na.rm = TRUE),
  avg_suppliers    = mean(vencedores_distintos,    na.rm = TRUE)
), by = sigla_uf]

# Non-competitive, deserted, unsuccessful (as % of total tenders)
counts_nc <- merge(dt_stats, total_tenders[, .(sigla_uf, n_tenders)], by = "sigla_uf")
counts_nc[, pct_noncompetitive := 100 * non_competitive_tender / n_tenders]
counts_nc[, pct_deserted       := 100 * deserted_tender        / n_tenders]
counts_nc[, pct_unsuccessful   := 100 * unsuccessful_tender    / n_tenders]

# Non-competitive value share
dt_valor[, pct_nc_value := 100 * non_competitive_share_valor_corrigido]

# Participants, suppliers, firms (by state)
dt_part_uf[, pct_firms := 100 * firmas_vencedoras / vencedores_distintos]
setnames(dt_part_uf,
         c("participantes_distintos", "vencedores_distintos"),
         c("n_participants", "n_suppliers"))

# ---- Merge all ----

summary <- Reduce(function(a, b) merge(a, b, by = "sigla_uf", all = TRUE),
                  list(total_tenders,
                       with_items, avg_items, with_part, avg_part,
                       counts_nc[, .(sigla_uf, pct_noncompetitive, pct_deserted, pct_unsuccessful)],
                       dt_valor[, .(sigla_uf, pct_nc_value)],
                       dt_part_uf[, .(sigla_uf, n_participants, n_suppliers, pct_firms)]))

summary[, state := factor(sigla_uf, levels = STATES)]
setorder(summary, state)

# ---- Add total row ----

total_row <- data.table(
  state            = "Total",
  n_tenders        = sum(summary$n_tenders,        na.rm = TRUE),
  n_municipalities = sum(summary$n_municipalities, na.rm = TRUE),
  pct_with_items   = weighted.mean(summary$pct_with_items,   summary$n_tenders, na.rm = TRUE),
  avg_items        = weighted.mean(summary$avg_items,        summary$n_tenders, na.rm = TRUE),
  pct_with_part    = weighted.mean(summary$pct_with_part,    summary$n_tenders, na.rm = TRUE),
  avg_participants = weighted.mean(summary$avg_participants, summary$n_tenders, na.rm = TRUE),
  avg_suppliers    = weighted.mean(summary$avg_suppliers,    summary$n_tenders, na.rm = TRUE),
  pct_noncompetitive = weighted.mean(summary$pct_noncompetitive, summary$n_tenders, na.rm = TRUE),
  pct_nc_value     = weighted.mean(summary$pct_nc_value,    summary$n_tenders, na.rm = TRUE),
  pct_deserted     = weighted.mean(summary$pct_deserted,    summary$n_tenders, na.rm = TRUE),
  pct_unsuccessful = weighted.mean(summary$pct_unsuccessful,summary$n_tenders, na.rm = TRUE),
  n_participants   = sum(summary$n_participants, na.rm = TRUE),
  n_suppliers      = sum(summary$n_suppliers,   na.rm = TRUE),
  pct_firms        = weighted.mean(summary$pct_firms, summary$n_suppliers, na.rm = TRUE)
)

summary_out <- rbind(summary[, .(state = as.character(state), n_tenders, n_municipalities,
                                  pct_with_items, avg_items, pct_with_part,
                                  avg_participants, avg_suppliers,
                                  pct_noncompetitive, pct_nc_value,
                                  pct_deserted, pct_unsuccessful,
                                  n_participants, n_suppliers, pct_firms)],
                     total_row, fill = TRUE)

# ---- Format and export ----

fmt_int <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")
fmt_pct <- function(x) ifelse(is.na(x), "—", sprintf("%.1f", x))
fmt_avg <- function(x) ifelse(is.na(x), "—", sprintf("%.1f", x))

display <- data.frame(
  State                         = summary_out$state,
  `Tenders`                     = fmt_int(summary_out$n_tenders),
  `Municipalities`              = fmt_int(summary_out$n_municipalities),
  `With items (\\%)`            = fmt_pct(summary_out$pct_with_items),
  `Avg items`                   = fmt_avg(summary_out$avg_items),
  `With participants (\\%)`     = fmt_pct(summary_out$pct_with_part),
  `Avg participants`            = fmt_avg(summary_out$avg_participants),
  `Avg suppliers`               = fmt_avg(summary_out$avg_suppliers),
  `Non-competitive (\\%)`       = fmt_pct(summary_out$pct_noncompetitive),
  `NC value (\\%)`              = fmt_pct(summary_out$pct_nc_value),
  `Deserted (\\%)`              = fmt_pct(summary_out$pct_deserted),
  `Unsuccessful (\\%)`          = fmt_pct(summary_out$pct_unsuccessful),
  `Participants`                = fmt_int(summary_out$n_participants),
  `Suppliers`                   = fmt_int(summary_out$n_suppliers),
  `Firms among suppliers (\\%)` = fmt_pct(summary_out$pct_firms),
  check.names = FALSE, stringsAsFactors = FALSE
)

fwrite(summary_out, file.path(table_output, "descriptive_statistics_procurement.csv"))

latex_tab <- kableExtra::kable(display, format = "latex", booktabs = TRUE,
                               escape = FALSE,
                               caption = "Descriptive Statistics: Procurement") |>
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down")) |>
  kableExtra::row_spec(nrow(display), bold = TRUE)

writeLines(latex_tab, file.path(table_output, "descriptive_statistics_procurement.tex"))
