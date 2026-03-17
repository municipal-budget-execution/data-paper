# code/analysis/tab_descriptive_municipalities.R
# Output: Tab 1 (descriptive statistics for municipalities)
#
# Input CSV: municipios.csv
# Columns: id_municipio, sigla_uf, populacao_2015, pib_per_capita_2015,
#   mortalidade_infantil_5_anos_2010, percentual_agua_encanada_2010,
#   percentual_coleta_lixo_2010, percentual_energia_eletrica_2010,
#   receitas_totais_per_capita_2015, receitas_correntes_per_capita_2015,
#   receitas_impostos_locais_per_capita_2015, receitas_capital_per_capita_2015

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("kableExtra", install = TRUE, character.only = TRUE)

# ---- Load data ----

mun <- fread(file.path(bigquery, "municipios.csv"))

SAMPLE_STATES <- c("RS", "PR", "SP", "MG", "CE", "PB", "PE")
mun[, in_sample := as.integer(sigla_uf %in% SAMPLE_STATES)]

# ---- Variable mapping ----

vars <- c("populacao_2015", "pib_per_capita_2015",
          "mortalidade_infantil_5_anos_2010",
          "percentual_agua_encanada_2010",
          "percentual_coleta_lixo_2010",
          "percentual_energia_eletrica_2010",
          "receitas_totais_per_capita_2015",
          "receitas_correntes_per_capita_2015",
          "receitas_impostos_locais_per_capita_2015",
          "receitas_capital_per_capita_2015")

var_labels <- c("Population (2015)",
                "GDP per capita (2015)",
                "Child mortality under 5 (2010)",
                "Piped water (\\%, 2010)",
                "Trash collection (\\%, 2010)",
                "Electricity access (\\%, 2010)",
                "Total revenues p.c. (2015)",
                "Current revenues p.c. (2015)",
                "Local tax revenues p.c. (2015)",
                "Capital revenues p.c. (2015)")

# ---- Compute means ----

col_means <- function(dt) {
  sapply(vars, function(v) mean(dt[[v]], na.rm = TRUE))
}

means_in  <- col_means(mun[in_sample == 1])
means_out <- col_means(mun[in_sample == 0])

# ---- Tab 1: In-sample vs. outside-sample ----

tab <- data.frame(
  Variable       = var_labels,
  In_sample      = sprintf("%.1f", means_in),
  Outside_sample = sprintf("%.1f", means_out),
  stringsAsFactors = FALSE
)

latex_tab <- kableExtra::kable(tab, format = "latex", booktabs = TRUE,
                               col.names = c("Variable", "In-sample", "Outside-sample"),
                               escape = FALSE,
                               caption = "Descriptive Statistics: Municipalities") |>
  kableExtra::kable_styling(latex_options = c("hold_position"))

writeLines(latex_tab,
           file.path(table_output, "descriptive_statistics_municipalities.tex"))

# ---- Tab 1 (by state) ----

means_states <- setNames(
  lapply(SAMPLE_STATES, function(s) col_means(mun[sigla_uf == s])),
  SAMPLE_STATES
)

tab_state <- as.data.frame(
  c(list(Variable = var_labels),
    lapply(means_states, function(m) sprintf("%.1f", m)),
    list(Outside_sample = sprintf("%.1f", means_out))),
  stringsAsFactors = FALSE
)

latex_tab_state <- kableExtra::kable(tab_state, format = "latex", booktabs = TRUE,
                                     col.names = c("Variable", SAMPLE_STATES, "Outside-sample"),
                                     escape = FALSE,
                                     caption = "Descriptive Statistics: Municipalities by State") |>
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down"))

writeLines(latex_tab_state,
           file.path(table_output, "descriptive_statistics_municipalities_by_state.tex"))
