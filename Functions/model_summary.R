model_summary <- function(reg, output, list_names, notes, rows, coef_omit_list) {
  
  # we save the output in latex
  gm <- tibble::tribble(
    ~raw,        ~clean,          ~fmt,
    "nobs",      "N",             0,
    "Mean of DV","Mean of Dep Var", 2,
    "r.squared", "R^{2}", 2,
    "adj.r.squared", "Adj R^{2}", 2
  )
  
  model = modelsummary::modelsummary(
    reg, 
    coef_rename = list_names,
    omit = coef_omit_list,
    fmt = NULL, 
    estimate = "{round(estimate, 3)}{stars}",
    statistic = "({(round(std.error, 3))})",
    stars = TRUE, 
    gof_map = gm,
    add_rows = rows,
    escape = FALSE,
    notes = notes)
  
}