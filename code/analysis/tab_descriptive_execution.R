# code/analysis/tab_descriptive_execution.R
# Output: Tab 3 (descriptive statistics for budget execution)
#
# Input CSVs (pre-downloaded by code/build/ingest_bigquery.R):
#   empenho_liquidacao.csv          — % commitments with verification
#   empenho_pagamento.csv           — % commitments with payment
#   empenho.csv                     — commitment counts by state
#   liquidacao.csv                  — verification counts by state
#   pagamento.csv                   — payment counts and distinct sellers by state
#   total_pagamento_ano.csv         — payment amounts by state and year
#   empenho_pe.csv                  — PE-specific commitment counts (no id_empenho_bd)
#   liq_pag_pe.csv                  — PE-specific verification and payment counts
#   ipca_anual.csv                  — IPCA annual inflation rates

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("kableExtra", install = TRUE, character.only = TRUE)

STATES <- c("CE", "MG", "PB", "PE", "PR", "RS", "SP")

# ---- Load CSVs ----

dt_emp_liq   <- fread(file.path(input, "empenho_liquidacao.csv"))
dt_emp_pag   <- fread(file.path(input, "empenho_pagamento.csv"))
dt_emp       <- fread(file.path(input, "empenho.csv"))
dt_liq       <- fread(file.path(input, "liquidacao.csv"))
dt_pag       <- fread(file.path(input, "pagamento.csv"))
dt_pag_ano   <- fread(file.path(input, "total_pagamento_ano.csv"))
dt_emp_pe    <- fread(file.path(input, "empenho_pe.csv"))
dt_lp_pe     <- fread(file.path(input, "liq_pag_pe.csv"))
dt_ipca      <- fread(file.path(input, "ipca_anual.csv"))

# ---- Deflate payment amounts to 2021 BRL using IPCA ----

# dt_ipca expected columns: year, ipca_rate (annual rate, 0–100 scale)
# Build cumulative deflation factor so 2021 = 1.0
dt_ipca <- dt_ipca[order(year)]
dt_ipca[, factor_2021 := cumprod(1 + ipca_rate / 100)]
base_2021 <- dt_ipca[year == 2021, factor_2021]
dt_ipca[, deflator := base_2021 / factor_2021]  # multiply payment amounts by this

dt_pag_ano <- merge(dt_pag_ano, dt_ipca[, .(year, deflator)], by = "year", all.x = TRUE)
dt_pag_ano[, total_payment_deflated := total_payment * deflator]

# Aggregate total payment (2021 BRL, billions) by state
payment_total <- dt_pag_ano[, .(
  total_payment_bn = sum(total_payment_deflated, na.rm = TRUE) / 1e9
), by = sigla_uf]
setnames(payment_total, "sigla_uf", "state")

# ---- Build summary by state (non-PE states) ----

# Helper: keep only in-sample states
keep_states <- function(dt, state_col = "sigla_uf") {
  dt[get(state_col) %in% setdiff(STATES, "PE")]
}

# Commitment stats
emp_sum <- keep_states(dt_emp)[, .(
  state        = sigla_uf,
  n_emp        = total_empenhos,
  pct_positive = 100 * share_positivo,
  pct_procure  = 100 * share_procurement
)]

# % with verification info
liq_share <- keep_states(dt_emp_liq)[, .(
  state        = sigla_uf,
  pct_with_liq = 100 * share_with_liquidacao
)]

# % with payment info
pag_share <- keep_states(dt_emp_pag)[, .(
  state        = sigla_uf,
  pct_with_pag = 100 * share_with_pagamento
)]

# Verification counts
liq_sum <- keep_states(dt_liq)[, .(
  state  = sigla_uf,
  n_liq  = total_liquidacoes
)]

# Payment counts + distinct sellers
pag_sum <- keep_states(dt_pag)[, .(
  state      = sigla_uf,
  n_pag      = total_pagamentos,
  n_sellers  = distinct_sellers,
  n_mun_pag  = distinct_municipalities
)]

# Merge all
summary <- Reduce(function(a, b) merge(a, b, by = "state", all = TRUE),
                  list(emp_sum, liq_share, pag_share, liq_sum, pag_sum))

# Add total payments
summary <- merge(summary, payment_total, by = "state", all.x = TRUE)

# ---- Append PE rows (PE doesn't have id_empenho_bd linking) ----

pe_emp <- dt_emp_pe[, .(
  state        = "PE",
  n_emp        = total_empenhos,
  pct_positive = 100 * share_positivo,
  pct_procure  = 100 * share_procurement,
  pct_with_liq = NA_real_,
  pct_with_pag = NA_real_
)]

pe_lp <- dt_lp_pe[, .(
  state      = "PE",
  n_liq      = total_liquidacoes,
  n_pag      = total_pagamentos,
  n_sellers  = distinct_sellers,
  n_mun_pag  = distinct_municipalities
)]

pe_row <- merge(pe_emp, pe_lp, by = "state", all = TRUE)
pe_row <- merge(pe_row, payment_total[state == "PE"], by = "state", all.x = TRUE)

summary <- rbind(summary, pe_row, fill = TRUE)

# State ordering
summary[, state := factor(state, levels = STATES)]
setorder(summary, state)

# ---- Add total row ----

total_row <- data.table(
  state        = "Total",
  n_emp        = sum(summary$n_emp,       na.rm = TRUE),
  pct_positive = weighted.mean(summary$pct_positive, summary$n_emp, na.rm = TRUE),
  pct_procure  = weighted.mean(summary$pct_procure,  summary$n_emp, na.rm = TRUE),
  pct_with_liq = weighted.mean(summary$pct_with_liq, summary$n_emp, na.rm = TRUE),
  pct_with_pag = weighted.mean(summary$pct_with_pag, summary$n_emp, na.rm = TRUE),
  n_liq        = sum(summary$n_liq,       na.rm = TRUE),
  n_pag        = sum(summary$n_pag,       na.rm = TRUE),
  n_sellers    = sum(summary$n_sellers,   na.rm = TRUE),
  n_mun_pag    = sum(summary$n_mun_pag,   na.rm = TRUE),
  total_payment_bn = sum(summary$total_payment_bn, na.rm = TRUE)
)

summary_out <- rbind(summary, total_row, fill = TRUE)

# ---- Format ----

fmt_int  <- function(x) formatC(as.integer(x), format = "d", big.mark = ",")
fmt_pct  <- function(x) ifelse(is.na(x), "—", sprintf("%.1f", x))
fmt_bn   <- function(x) sprintf("%.1f", x)

display <- data.frame(
  State                           = as.character(summary_out$state),
  `Commitments`                   = fmt_int(summary_out$n_emp),
  `Positive (\\%)`                = fmt_pct(summary_out$pct_positive),
  `Procurement-related (\\%)`     = fmt_pct(summary_out$pct_procure),
  `With verification (\\%)`       = fmt_pct(summary_out$pct_with_liq),
  `With payment (\\%)`            = fmt_pct(summary_out$pct_with_pag),
  `Verifications`                 = fmt_int(summary_out$n_liq),
  `Payments`                      = fmt_int(summary_out$n_pag),
  `Distinct sellers`              = fmt_int(summary_out$n_sellers),
  `Municipalities`                = fmt_int(summary_out$n_mun_pag),
  `Total payments (BRL bn, 2021)` = fmt_bn(summary_out$total_payment_bn),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

# Save CSV
fwrite(summary_out, file.path(table_output, "descriptive_statistics_execution.csv"))

# Save LaTeX
latex_tab <- kableExtra::kable(display, format = "latex", booktabs = TRUE,
                               escape = FALSE,
                               caption = "Descriptive Statistics: Budget Execution") |>
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down")) |>
  kableExtra::row_spec(nrow(display), bold = TRUE)

writeLines(latex_tab, file.path(table_output, "descriptive_statistics_execution.tex"))
