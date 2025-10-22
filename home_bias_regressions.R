
{
  
  # Define regression models
  reg_models <- list(
    same_municipality   ~ log(gdp) + log(population) + procurement_municipality + discretionary,
    same_municipality   ~ log(gdp) + log(population) + procurement_municipality + discretionary | year,
    same_municipality   ~ log(gdp) + log(population) + procurement_municipality + discretionary | state + year,
    same_municipality   ~ log(gdp) + log(population) + procurement_municipality + discretionary | municipality + year
  )
  
  # Run regression for each model
  reg_results <- lapply(reg_models, function(model) fixest::feols(model, data = df.municipality_year))
  
  # Variable names and descriptions
  dict <- c(
    "same_municipality" = "\\% Local Suppliers",
    "log(gdp)" = "ln(GDP)",
    "log(population)" = "ln(Population)",
    "discretionary" = "\\% Non-Competitive Tenders"
  )
  
  # Create tables
  fixest::setFixest_etable(digits.stats = 2, drop = c("Constant"))
  table_a1 <- fixest::etable(
    reg_results,
    title = "Correlations",
    fitstat = c("n", "my", "rmse", "r2", "ar2"),
    digits = 3,
    tex = TRUE,
    dict = dict
  )
  
  table_a1 <- c(
    table_a1[1:6],
    " \\cmidrule(lr){2-5} ",
    table_a1[7:13],
    table_a1[16:17],
    "\\\\",
    "  Year Fixed Effects          & \\xmark & \\checkmark & \\checkmark & \\checkmark \\\\  ",
    "  State Fixed Effects         & \\xmark & \\xmark     & \\checkmark & \\xmark     \\\\  ",
    "  Municipality Fixed Effects  & \\xmark & \\xmark     & \\xmark     & \\checkmark \\\\  ",
    "\\midrule",
    table_a1[23:length(table_a1)]
  )
  
  pdf_table(table_a1, file_name = file.path(table_output, "reg_home_bias.tex"))
  
}
