# code/analysis/tab_regressions_home_bias.R
# Output: Home bias regression table (Tab: local suppliers)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/pdf_table.R"))

pacman::p_load("fixest", install = TRUE, character.only = TRUE)

# ---- Load data ----

data_munic <- fread(file.path(input, "full_budget_execution_index.csv"),
                    showProgress = FALSE, encoding = "Latin-1")

home_bias_mun_year <- fread(file.path(input, "home_bias_municipality_year.csv"))
home_bias_mun_year <- home_bias_mun_year[vencedor == 1]
setnames(home_bias_mun_year,
         c("municipality", "state", "year", "winner", "discretionary", "same_municipality", "same_state"))
home_bias_mun_year <- merge(data_munic, home_bias_mun_year,
                            by = c("municipality", "state", "year"), all.x = TRUE)

# ---- Regression models ----

reg_models <- list(
  same_municipality ~ log(gdp) + log(population) + procurement_municipality + discretionary,
  same_municipality ~ log(gdp) + log(population) + procurement_municipality + discretionary | year,
  same_municipality ~ log(gdp) + log(population) + procurement_municipality + discretionary | state + year,
  same_municipality ~ log(gdp) + log(population) + procurement_municipality + discretionary | municipality + year
)

reg_results <- lapply(reg_models, function(model) fixest::feols(model, data = home_bias_mun_year))

dict <- c(
  "same_municipality"       = "\\% Local Suppliers",
  "log(gdp)"                = "ln(GDP)",
  "log(population)"         = "ln(Population)",
  "discretionary"           = "\\% Non-Competitive Tenders"
)

fixest::setFixest_etable(digits.stats = 2, drop = c("Constant"))
table_hb <- fixest::etable(reg_results,
                           title   = "Correlations",
                           fitstat = c("n", "my", "rmse", "r2", "ar2"),
                           digits  = 3, tex = TRUE, dict = dict)

table_hb <- c(
  table_hb[1:6],
  " \\cmidrule(lr){2-5} ",
  table_hb[7:13],
  table_hb[16:17],
  "\\\\",
  "  Year Fixed Effects          & \\xmark & \\checkmark & \\checkmark & \\checkmark \\\\  ",
  "  State Fixed Effects         & \\xmark & \\xmark     & \\checkmark & \\xmark     \\\\  ",
  "  Municipality Fixed Effects  & \\xmark & \\xmark     & \\xmark     & \\checkmark \\\\  ",
  "\\midrule",
  table_hb[23:length(table_hb)]
)

pdf_table(table_hb, file_name = file.path(table_output, "reg_home_bias.tex"))
