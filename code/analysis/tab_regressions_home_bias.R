# code/analysis/tab_regressions_home_bias.R
#
# Outputs (all to output/figures/ because the paper reads them via \input{figures/...}):
#   output/figures/reg_home_bias_correlates.tex     (main paper Tab 4)
#
# Note: The federal-comparison tables (regression_home_bias.tex, weighted variants)
#       and the value-weighted correlates table (reg_home_bias_correlates_weighted.tex)
#       are produced by code/analysis/fig_home_bias_federal.R, which requires
#       intermediate data built by code/build/API_ComprasDados/BuildHomeBiasFederalEntities.R.
#
# Data inputs (all in Data/Raw/):
#   participante_cnpj.csv          — tender-participant rows, one row per (tender × participant)
#   full_budget_execution_index.csv — municipality-year level: gdp, population

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("fixest", install = TRUE, character.only = TRUE)

# ---- Load data ----

part <- fread(file.path(input, "participante_cnpj.csv"))

# Filter to winners only
part <- part[vencedor == 1]

# Outcome: same municipality (tender municipality == supplier municipality)
part[, same_municipality := as.integer(!is.na(id_municipio_1) &
                                          id_municipio_1 == id_municipio)]

# Key covariate: non-competitive tender (waiver = 8, direct contracting = 10)
part[, non_competitive := as.integer(modalidade %in% c(8L, 10L))]

# Rename for merge
setnames(part, c("id_municipio", "sigla_uf", "ano"),
               c("municipality",  "state",     "year"))

# Municipality characteristics (GDP and population)
mun_char <- fread(file.path(input, "full_budget_execution_index.csv"),
                  select = c("municipality", "state", "year", "gdp", "population"),
                  showProgress = FALSE)

part <- merge(part, mun_char, by = c("municipality", "state", "year"), all.x = TRUE)
part <- part[!is.na(gdp) & !is.na(population) & gdp > 0 & population > 0]

# ---- Regression models: 3 columns, no FE / year FE / state+year FE ----

m1 <- feols(same_municipality ~ log(gdp) + log(population) + non_competitive,
            data = part, cluster = ~municipality)

m2 <- feols(same_municipality ~ log(gdp) + log(population) + non_competitive | year,
            data = part, cluster = ~municipality)

m3 <- feols(same_municipality ~ log(gdp) + log(population) + non_competitive | state + year,
            data = part, cluster = ~municipality)

# ---- Format and write table ----

dict <- c(
  "same_municipality" = "Local Supplier",
  "log(gdp)"          = "ln(GDP)",
  "log(population)"   = "ln(Population)",
  "non_competitive"   = "Non-Competitive Tender"
)

fixest::setFixest_etable(digits.stats = 2)

# Get table as character vector; suppress auto FE rows (we add them manually)
tbl_raw <- fixest::etable(
  m1, m2, m3,
  fitstat   = c("n", "my", "rmse", "r2", "ar2"),
  digits    = 3,
  tex       = TRUE,
  dict      = dict,
  drop      = "Constant",
  style.tex = style.tex(
    signif.code  = c("***" = 0.01, "**" = 0.05, "*" = 0.1),
    notes.intro  = ""
  )
)

# Insert \cmidrule(lr){2-4} after the "Dependent Variable:" line
dep_idx <- grep("Dependent Variable", tbl_raw)
if (length(dep_idx) > 0) {
  tbl_raw <- c(tbl_raw[seq_len(dep_idx)],
               "   \\cmidrule(lr){2-4}",
               tbl_raw[(dep_idx + 1L):length(tbl_raw)])
}

# Find "Fit statistics" row; insert FE block before the \midrule that precedes it
fs_idx <- grep("Fit statistics", tbl_raw)
stopifnot(length(fs_idx) == 1L)

# The \midrule immediately before "Fit statistics" is at fs_idx - 1
# Insert our custom FE block before that \midrule
fe_block <- c(
  "   \\midrule",
  "   \\emph{Fixed-effects}\\\\",
  "   Year  & \\xmark & \\checkmark & \\checkmark \\\\  ",
  "   State & \\xmark & \\xmark     & \\checkmark \\\\  "
)

tbl_out <- c(
  tbl_raw[seq_len(fs_idx - 2L)],   # everything before the pre-FS \midrule
  fe_block,
  tbl_raw[(fs_idx - 1L):length(tbl_raw)]   # pre-FS \midrule through end
)

writeLines(tbl_out, file.path(table_output, "reg_home_bias_correlates.tex"))
cat("  Wrote: output/tables/reg_home_bias_correlates.tex\n")
