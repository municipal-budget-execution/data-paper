# code/analysis/tab_regressions_delay.R
# Outputs: Tab 4 (regressions of payment delay on GDP and population)
#          Tab 5 (regressions of SICONFI deviations)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/pdf_table.R"))

pacman::p_load("fixest", install = TRUE, character.only = TRUE)

# ---- Load data ----

data_munic <- fread(file.path(input, "full_budget_execution_index.csv"),
                    showProgress = FALSE, encoding = "Latin-1")

home_bias <- fread(file.path(input, "home_bias.csv"))
home_bias <- home_bias[vencedor == 1]
setnames(home_bias, c("municipality", "state", "year", "winner", "same_municipality", "same_state"))
home_bias <- merge(data_munic, home_bias, by = c("municipality", "state", "year"), all.x = TRUE)

home_bias[, (grep("^over_", names(home_bias))) := lapply(.SD, function(x) x * 100),
          .SDcols = grep("^over_", names(home_bias))]

# ---- Tab 4: Payment delay regressions ----

variables  <- c("wavg_delay", "over_30days", "over_45days", "over_60days")
reg_models <- list()
reg_results <- list()
i <- 0

for (outcome in variables) {
  i <- i + 1
  reg_models[[i]] <- as.formula(paste0(outcome, " ~ log(gdp) + log(population)"))
  i <- i + 1
  reg_models[[i]] <- as.formula(paste0(outcome, " ~ log(gdp) + log(population) | state + year"))

  for (reg in seq(i - 1, i)) {
    reg_results[[reg]] <- fixest::feols(reg_models[[reg]],
                                        data = home_bias[state != "PE"][year %in% 2014:2020])
  }
}

dict <- c(
  "wavg_delay"  = "Average Payment Speed",
  "over_30days" = "\\% Over 30 Days",
  "over_45days" = "\\% Over 45 Days",
  "over_60days" = "\\% Over 60 Days",
  "log(gdp)"        = "ln(GDP)",
  "log(population)" = "ln(Population)"
)

fixest::setFixest_etable(digits.stats = 2, drop = c("Constant"))

table_4 <- fixest::etable(reg_results[seq(2, 8, by = 2)],
                          fitstat = c("n", "my", "rmse", "r2", "ar2"),
                          digits = 3, tex = TRUE, dict = dict, notes = FALSE,
                          style.tex = style.tex(notes.intro = "", signif.code = FALSE))
table_4 <- c(table_4[1:10], "\\\\",
             "  Year Fixed Effects  & \\checkmark  & \\checkmark   & \\checkmark  & \\checkmark \\\\ ",
             "  State Fixed Effects   & \\checkmark  & \\checkmark   & \\checkmark  & \\checkmark\\\\",
             "\\midrule \\midrule", table_4[18:length(table_4)])

pdf_table(table_4, file_name = file.path(table_output, "table_reg_4_columns.tex"))

# ---- Tab 5: SICONFI deviation regressions ----

cols_to_winsorize <- c("proportion_verification", "proportion_commitment", "proportion_payment")
for (col in cols_to_winsorize) {
  q05 <- quantile(home_bias[[col]], 0.05, na.rm = TRUE)
  q95 <- quantile(home_bias[[col]], 0.95, na.rm = TRUE)
  home_bias[, (col) := pmax(pmin(get(col), q95), q05)]
}

reg_models_5 <- list(
  proportion_commitment   ~ log(gdp) + log(population) + procurement_municipality,
  proportion_commitment   ~ log(gdp) + log(population) + procurement_municipality | year,
  proportion_commitment   ~ log(gdp) + log(population) + procurement_municipality | state + year,
  proportion_commitment   ~ log(gdp) + log(population) + procurement_municipality | municipality + year,
  proportion_verification ~ log(gdp) + log(population) + procurement_municipality,
  proportion_verification ~ log(gdp) + log(population) + procurement_municipality | year,
  proportion_verification ~ log(gdp) + log(population) + procurement_municipality | state + year,
  proportion_verification ~ log(gdp) + log(population) + procurement_municipality | municipality + year,
  proportion_payment      ~ log(gdp) + log(population) + procurement_municipality,
  proportion_payment      ~ log(gdp) + log(population) + procurement_municipality | year,
  proportion_payment      ~ log(gdp) + log(population) + procurement_municipality | state + year,
  proportion_payment      ~ log(gdp) + log(population) + procurement_municipality | municipality + year
)

reg_results_5 <- lapply(reg_models_5, function(model) fixest::feols(model, data = home_bias))

dict_5 <- c(
  "proportion_commitment"   = "Commitment (p.p)",
  "proportion_verification" = "Verification (p.p)",
  "proportion_payment"      = "Payment (p.p)",
  "log(gdp)"                = "ln(GDP)",
  "log(population)"         = "ln(Population)"
)

fixest::setFixest_etable(digits.stats = 2, drop = c("Constant"))
table_5 <- fixest::etable(reg_results_5,
                          title   = "Correlation of deviations in percentage points from Treasury Data",
                          fitstat = c("n", "my", "rmse", "r2", "ar2"),
                          digits  = 3, tex = TRUE, dict = dict_5, notes = FALSE,
                          style.tex = style.tex(notes.intro = "", signif.code = FALSE))

table_5 <- c(
  table_5[1:6],
  " \\cmidrule(lr){2-5} \\cmidrule(lr){6-9} \\cmidrule(lr){10-13} ",
  table_5[7:13],
  "\\\\",
  "  Year Fixed Effects          & \\xmark & \\checkmark & \\checkmark & \\checkmark & \\xmark & \\checkmark & \\checkmark & \\checkmark & \\xmark & \\checkmark & \\checkmark & \\checkmark \\\\  ",
  "  State Fixed Effects         & \\xmark & \\xmark     & \\checkmark & \\xmark     & \\xmark & \\xmark     & \\checkmark & \\xmark     & \\xmark & \\xmark     & \\checkmark & \\xmark     \\\\  ",
  "  Municipality Fixed Effects  & \\xmark & \\xmark     & \\xmark     & \\checkmark & \\xmark & \\xmark     & \\xmark     & \\checkmark & \\xmark & \\xmark     & \\xmark     & \\checkmark \\\\  ",
  "\\midrule",
  table_5[21:length(table_5)]
)

pdf_table(table_5, file_name = file.path(table_output, "reg_deviations.tex"))
