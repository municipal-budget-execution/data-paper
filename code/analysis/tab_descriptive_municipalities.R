# code/analysis/tab_descriptive_municipalities.R
# Output: Tab 1 (descriptive statistics for municipalities)
#   Two columns: in-sample vs. outside-sample municipality means.
#   Also produces a by-state version.
#
# Input CSV (pre-downloaded by code/build/ingest_bigquery.R):
#   municipios.csv
#   Expected columns: id_municipio, sigla_uf, populacao, pib_per_capita,
#     mortalidade_infantil, agua_encanada, coleta_lixo, acesso_eletricidade,
#     receita_total_pc, receita_corrente_pc, receita_tributaria_pc, receita_capital_pc

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("kableExtra", install = TRUE, character.only = TRUE)

# ---- Load data ----

mun <- fread(file.path(input, "municipios.csv"))

SAMPLE_STATES <- c("RS", "PR", "SP", "MG", "CE", "PB", "PE")

mun[, in_sample := as.integer(sigla_uf %in% SAMPLE_STATES)]

# ---- Variable definitions ----

vars <- c(
  "populacao",
  "pib_per_capita",
  "mortalidade_infantil",
  "agua_encanada",
  "coleta_lixo",
  "acesso_eletricidade",
  "receita_total_pc",
  "receita_corrente_pc",
  "receita_tributaria_pc",
  "receita_capital_pc"
)

var_labels <- c(
  "Population (2015)",
  "GDP per capita (2015)",
  "Child mortality under 5 (2010)",
  "Piped water (\\%, 2010)",
  "Trash collection (\\%, 2010)",
  "Electricity access (\\%, 2010)",
  "Total revenues p.c. (2015)",
  "Current revenues p.c. (2015)",
  "Local tax revenues p.c. (2015)",
  "Capital revenues p.c. (2015)"
)

# ---- Summary function ----

col_means <- function(dt, vars) {
  sapply(vars, function(v) {
    x <- dt[[v]]
    if (all(is.na(x))) return(NA_real_)
    mean(x, na.rm = TRUE)
  })
}

# ---- Tab 1: In-sample vs. outside-sample ----

means_in  <- col_means(mun[in_sample == 1], vars)
means_out <- col_means(mun[in_sample == 0], vars)

tab <- data.frame(
  Variable       = var_labels,
  In_sample      = sprintf("%.1f", means_in),
  Outside_sample = sprintf("%.1f", means_out),
  stringsAsFactors = FALSE
)

# Format as LaTeX
latex_tab <- kableExtra::kable(tab, format = "latex", booktabs = TRUE,
                               col.names = c("Variable", "In-sample", "Outside-sample"),
                               escape = FALSE,
                               caption = "Descriptive Statistics: Municipalities") |>
  kableExtra::kable_styling(latex_options = c("hold_position"))

writeLines(latex_tab, file.path(table_output, "descriptive_statistics_municipalities.tex"))

# ---- Tab 1 (by state): one column per in-sample state + Outside ----

means_states <- lapply(SAMPLE_STATES, function(s) {
  col_means(mun[sigla_uf == s], vars)
})
names(means_states) <- SAMPLE_STATES

tab_state <- as.data.frame(
  c(list(Variable = var_labels),
    lapply(means_states, function(m) sprintf("%.1f", m)),
    list(Outside_sample = sprintf("%.1f", means_out))),
  stringsAsFactors = FALSE
)

col_names_state <- c("Variable", SAMPLE_STATES, "Outside-sample")

latex_tab_state <- kableExtra::kable(tab_state, format = "latex", booktabs = TRUE,
                                     col.names = col_names_state,
                                     escape = FALSE,
                                     caption = "Descriptive Statistics: Municipalities by State") |>
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down"))

writeLines(latex_tab_state,
           file.path(table_output, "descriptive_statistics_municipalities_by_state.tex"))
