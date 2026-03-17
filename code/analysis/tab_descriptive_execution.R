# code/analysis/tab_descriptive_execution.R
# Output: Tab 3 (descriptive statistics for budget execution)
#
# Input CSVs and their actual columns:
#   empenho_liquidacao.csv   sigla_uf, distinct_commitments, number_municipalities,
#                            procurement_commitments, has_verification_information
#   empenho_pagamento.csv    sigla_uf, has_payment_information
#   empenho.csv              sigla_uf, obs_commitments, total_positive_values
#   liquidacao.csv           sigla_uf, obs_verifications, distinct_verifications
#   pagamento.csv            sigla_uf, obs_payments, distinct_payments, distinct_sellers
#   total_pagamento_ano.csv  ano, sigla_uf, total_payment_billion  (BRL billion per year)
#   empenho_pe.csv           sigla_uf, obs_commitments, total_positive_values,
#                            number_municipalities, procurement_commitments
#   liq_pag_pe.csv           sigla_uf, obs_verifications, obs_payments
#   ipca_anual.csv           variacao_anual, ano, mes

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("kableExtra", install = TRUE, character.only = TRUE)

STATES <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")

# ---- Load CSVs ----

dt_emp_liq  <- fread(file.path(bigquery, "empenho_liquidacao.csv"))
dt_emp_pag  <- fread(file.path(bigquery, "empenho_pagamento.csv"))
dt_emp      <- fread(file.path(bigquery, "empenho.csv"))
dt_liq      <- fread(file.path(bigquery, "liquidacao.csv"))
dt_pag      <- fread(file.path(bigquery, "pagamento.csv"))
dt_pag_ano  <- fread(file.path(bigquery, "total_pagamento_ano.csv"))
dt_emp_pe   <- fread(file.path(bigquery, "empenho_pe.csv"))
dt_lp_pe    <- fread(file.path(bigquery, "liq_pag_pe.csv"))
dt_ipca     <- fread(file.path(input,   "ipca_anual.csv"))   # external IBGE data

# ---- Deflate payment totals to 2021 BRL ----
# total_pagamento_ano.csv has total_payment_billion per state-year (nominal BRL billions)
# Apply IPCA deflation to convert to 2021 BRL

dt_ipca <- dt_ipca[order(ano)]
dt_ipca[, cumulative := cumprod(1 + variacao_anual / 100)]
base_2021 <- dt_ipca[ano == 2021, cumulative]
dt_ipca[, deflator := base_2021 / cumulative]

dt_pag_ano <- merge(dt_pag_ano, dt_ipca[, .(ano, deflator)], by = "ano", all.x = TRUE)
dt_pag_ano[is.na(deflator), deflator := 1]
dt_pag_ano[, total_payment_deflated := total_payment_billion * deflator]

payment_total <- dt_pag_ano[sigla_uf %in% STATES,
                             .(total_payment_bn = sum(total_payment_deflated, na.rm = TRUE)),
                             by = sigla_uf]

# ---- Build summary for non-PE states ----

NON_PE <- setdiff(STATES, "PE")

# % positive commitments
emp_pos <- dt_emp[sigla_uf %in% NON_PE,
                  .(sigla_uf,
                    n_emp        = obs_commitments,
                    pct_positive = 100 * total_positive_values / obs_commitments)]

# % procurement-related, % with verification (from empenho_liquidacao)
liq_info <- dt_emp_liq[sigla_uf %in% NON_PE,
                        .(sigla_uf,
                          n_emp_liq    = distinct_commitments,
                          pct_procure  = 100 * procurement_commitments / distinct_commitments,
                          pct_with_liq = 100 * has_verification_information)]

# % with payment (from empenho_pagamento)
pag_info <- dt_emp_pag[sigla_uf %in% NON_PE,
                        .(sigla_uf, pct_with_pag = 100 * has_payment_information)]

# Verification counts
liq_cnt <- dt_liq[sigla_uf %in% NON_PE,
                  .(sigla_uf, n_liq = distinct_verifications)]

# Payment counts and sellers
pag_cnt <- dt_pag[sigla_uf %in% NON_PE,
                  .(sigla_uf, n_pag = distinct_payments, n_sellers = distinct_sellers)]

# Merge non-PE summary
summary <- Reduce(function(a, b) merge(a, b, by = "sigla_uf", all = TRUE),
                  list(emp_pos, liq_info[, .(sigla_uf, pct_procure, pct_with_liq)],
                       pag_info, liq_cnt, pag_cnt))
summary <- merge(summary, payment_total, by = "sigla_uf", all.x = TRUE)

# ---- Append PE row ----

pe_emp <- dt_emp_pe[, .(
  sigla_uf     = sigla_uf,
  n_emp        = obs_commitments,
  pct_positive = 100 * total_positive_values / obs_commitments,
  pct_procure  = 100 * procurement_commitments / obs_commitments,
  pct_with_liq = NA_real_,
  pct_with_pag = NA_real_
)]

pe_lp <- dt_lp_pe[, .(
  sigla_uf  = sigla_uf,
  n_liq     = obs_verifications,
  n_pag     = obs_payments,
  n_sellers = NA_integer_
)]

pe_row <- merge(pe_emp, pe_lp, by = "sigla_uf", all = TRUE)
pe_row <- merge(pe_row, payment_total[sigla_uf == "PE"], by = "sigla_uf", all.x = TRUE)
pe_row[, n_emp_liq := NA_real_]

summary <- rbind(summary, pe_row, fill = TRUE)
summary[, state := factor(sigla_uf, levels = STATES)]
setorder(summary, state)

# ---- Add total row ----

total_row <- data.table(
  state        = "Total",
  n_emp        = sum(summary$n_emp,        na.rm = TRUE),
  pct_positive = weighted.mean(summary$pct_positive, summary$n_emp, na.rm = TRUE),
  pct_procure  = weighted.mean(summary$pct_procure,  summary$n_emp, na.rm = TRUE),
  pct_with_liq = weighted.mean(summary$pct_with_liq, summary$n_emp, na.rm = TRUE),
  pct_with_pag = weighted.mean(summary$pct_with_pag, summary$n_emp, na.rm = TRUE),
  n_liq        = sum(summary$n_liq,        na.rm = TRUE),
  n_pag        = sum(summary$n_pag,        na.rm = TRUE),
  n_sellers    = sum(summary$n_sellers,    na.rm = TRUE),
  total_payment_bn = sum(summary$total_payment_bn, na.rm = TRUE)
)

summary_out <- rbind(
  summary[, .(state = as.character(state), n_emp, pct_positive, pct_procure,
              pct_with_liq, pct_with_pag, n_liq, n_pag, n_sellers, total_payment_bn)],
  total_row, fill = TRUE
)

# ---- Format and export ----

fmt_int <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")
fmt_pct <- function(x) ifelse(is.na(x), "—", sprintf("%.1f", x))
fmt_bn  <- function(x) ifelse(is.na(x), "—", sprintf("%.1f", x))

display <- data.frame(
  State                           = summary_out$state,
  `Commitments`                   = fmt_int(summary_out$n_emp),
  `Positive (\\%)`                = fmt_pct(summary_out$pct_positive),
  `Procurement-related (\\%)`     = fmt_pct(summary_out$pct_procure),
  `With verification (\\%)`       = fmt_pct(summary_out$pct_with_liq),
  `With payment (\\%)`            = fmt_pct(summary_out$pct_with_pag),
  `Verifications`                 = fmt_int(summary_out$n_liq),
  `Payments`                      = fmt_int(summary_out$n_pag),
  `Distinct sellers`              = fmt_int(summary_out$n_sellers),
  `Total payments (BRL bn, 2021)` = fmt_bn(summary_out$total_payment_bn),
  check.names = FALSE, stringsAsFactors = FALSE
)

fwrite(summary_out, file.path(table_output, "descriptive_statistics_execution.csv"))

latex_tab <- kableExtra::kable(display, format = "latex", booktabs = TRUE,
                               escape = FALSE,
                               caption = "Descriptive Statistics: Budget Execution") |>
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down")) |>
  kableExtra::row_spec(nrow(display), bold = TRUE)

writeLines(latex_tab, file.path(table_output, "descriptive_statistics_budget_execution.tex"))
