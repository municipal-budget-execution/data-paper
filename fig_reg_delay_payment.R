# ---------------------------------------------------------------------------- #
#                        Brazil Budget Execution Project                       #
#                              World Bank - DIME                               #
# ---------------------------------------------------------------------------- #

# ---- 1: Basic Cleaning and Setup ----
{
  
  # Convert fractions to percentages for all variables starting with 'over_'
  data_munic = data_munic[, (grep("^over_", names(data_munic))) := lapply(.SD, function(x) x * 100), 
                          .SDcols = grep("^over_", names(data_munic))]
  
  # We exclude it cause we don't have procurement data for this state
  data_plot = data_munic[state != "PE",][year %in% seq(2014, 2020),]
  
}


# ---- 2. Histogram + CDF of Weighted Payment Delays ----

{
  
  # Generate CDF plot for wavg_delay
  cdf_plot <- ggplot(data_plot, aes(wavg_delay)) +
    # Plot CDF line
    stat_ecdf(geom = "line", size = 2, color = "#17375E", linewidth = 1.2) +
    # Formatting and design details
    scale_x_continuous("Average Payment Delays", breaks = seq(10, 100, by = 10), limits = c(0, 105)) +
    coord_cartesian(expand = FALSE, clip = 'off') +
    scale_y_continuous("", limits = c(0, 1.1), breaks = seq(0.2, 1, by = .2)) +
    set_theme(axis_line_x = element_blank(),
              axis_line_y = element_line(),
              y_text_size = 15,
              x_text_size = 15, 
              size = 20) +
    ggtitle(label = "Fraction") + 
    theme(axis.line.x = element_line(color = 'black', size = 0.5),
          axis.ticks.length = unit(0.3, "cm"),
          axis.ticks.x = element_line(),
          axis.text.x = element_markdown(),
          plot.margin = unit(c(0.2, 0.2, 0, 0.1), "lines"),
          strip.background = element_rect(colour = "black", fill = "gray"),
          axis.title.x = element_markdown()) + 
    geom_vline(xintercept = 30, color = "black", linewidth = 0.5, linetype = "dashed", alpha = 0.6)
  
  # Save the CDF plot
  ggsave(
    filename = file.path(graph_output, "cdf_sample_wavg_delay_2.jpeg"),
    cdf_plot,
    width    = 14.14,
    height   = 8.51,
    dpi      = 400,
    units    = "in",
    device   = 'jpeg'
  )
  
  # Generate histogram plot for wavg_delay
  hist_plot <- ggplot(data_plot, aes(wavg_delay)) +
    # Plot histogram bars
    geom_histogram(linewidth = 0.8, color = "#0D3446",
                   fill = "#1A476F", alpha = 1, bins = 100) +
    # Formatting and design details identical to CDF plot
    scale_x_continuous("Average Payment Delays", breaks = seq(10, 100, by = 10), limits = c(0, 105)) +
    coord_cartesian(expand = FALSE, clip = 'off') +
    scale_y_continuous("") +
    set_theme(axis_line_x = element_blank(),
              axis_line_y = element_line(),
              y_text_size = 15,
              x_text_size = 15, 
              size = 20) +
    ggtitle(label = "Density") + 
    theme(axis.line.x = element_line(color = 'black', size = 0.5),
          axis.ticks.length = unit(0.3, "cm"),
          axis.ticks.x = element_line(),
          axis.text.x = element_markdown(),
          plot.margin = unit(c(0.2, 0.2, 0, 0.1), "lines"),
          strip.background = element_rect(colour = "black", fill = "gray"),
          axis.title.x = element_markdown()) + 
    geom_vline(xintercept = 30, color = "black", linewidth = 0.5, linetype = "dashed", alpha = 0.6)
  
  # Save the histogram plot
  ggsave(
    filename = file.path(graph_output, "hist_sample_wavg_delay_2.jpeg"),
    hist_plot,
    width    = 14.14,
    height   = 8.51,
    dpi      = 400,
    units    = "in",
    device   = 'jpeg'
  )
  
}

# ---- 3. CDF Across Years of Late Payments Over 30 Days ----

{
  
  # Define the years of interest
  years <- 2014:2020
  
  # Initialize an empty list to store plots for each year
  plot_list <- vector("list", length(years))
  
  # Generate CDF plots for late payments over 30 days across years
  for (i in seq_along(years)) {
    
    year_plot <- ggplot() +
      scale_x_continuous("", breaks = seq(10, 100, by = 10), limits = c(0, 105)) +
      coord_cartesian(expand = FALSE, clip = 'off') +
      scale_y_continuous("") +
      set_theme(axis_line_x = element_blank(),
                axis_line_y = element_line(),
                y_text_size = 15,
                x_text_size = 15, 
                size = 20) +
      ggtitle(label = as.character(years[i])) + 
      theme(axis.line.x = element_line(color = 'black', linewidth = 0.5),
            axis.ticks.length = unit(0.3, "cm"),
            axis.ticks.x = element_line(),
            axis.text.x = element_markdown(),
            plot.title  = element_text(hjust = 0.5, size = 18, color = "black", family = "LM Roman 10"),
            plot.margin = unit(c(0.2, 0.2, 0, 0.1), "lines"),
            strip.background = element_rect(colour = "black", fill = "gray"),
            axis.title.x = element_markdown()) +
      geom_vline(xintercept = 30, color = "black", linewidth = 0.5, linetype = "dashed", alpha = 0.6)
    
    for (j in 1:i) {
      data_year <- data_plot[data_plot$year == years[j],]
      year_plot <- year_plot + 
        stat_ecdf(data_year, mapping = aes(over_30days), geom = "line", size = ifelse(j == i, 1, 0.5), color = ifelse(j == i, "#17375E", "#6F7F94"), alpha = ifelse(j == i, 1, 0.4), linewidth = 0.5)
    }
    
    plot_list[[i]] <- year_plot
    
  }
  
  # Combine yearly plots into a grid
  combined_plot <- ggpubr::ggarrange(plotlist = plot_list, nrow = 3, ncol = 3, widths = c(0.1, 0.1, 0.1))
  
  # Save the combined plot
  ggsave(
    filename = file.path(graph_output, paste0("cdf_years_over_30days.jpeg")),
    combined_plot,
    width    = 14.14,
    height   = 8.51,
    dpi      = 400,
    units    = "in",
    device   = 'jpeg'
  )
  
}

# ---- 4. Binned Scatter Plot ----

{
  
  # Modify variable for the plot
  data_plot = data_plot[, log_gdp := log(gdp_per_capita)]
  
  # Create binned regression object
  binreg_object <- binsglm(data = data_plot, y = wavg_delay, x = log_gdp, randcut = 1, polyreg = 1)
  
  # Extract and customize the ggplot object
  binreg_plot <- binreg_object[["bins_plot"]] + 
    scale_x_continuous("Log (GDP per capita)") +
    ggtitle("Average Payment Delay") +
    coord_cartesian(expand = FALSE, clip = 'off') +
    scale_y_continuous("", limits = c(14, 24), breaks = seq(15, 23, by = 1)) +
    set_theme(axis_line_x = element_line(), axis_line_y = element_line())
  
  # Save the plot
  ggsave(filename = file.path(graph_output, "scatter_plot.jpeg"), binreg_plot, width = 14.14, height = 8.51, dpi = 400, units = "in", device = 'jpeg')
  
}

# ---- 5. Regression Analyses Part 1 ----
# 
{
  
  # Variables and setup
  variables <- c("wavg_delay", "over_30days", "over_45days", "over_60days")
  reg_models <- list()
  reg_results <- list()
  i = 0
  
  # Loop for regression models
  for (outcome in variables) {
    i = i + 1
    reg_models[[i]] <- as.formula(paste0(outcome, " ~ log(gdp) + log(population)"))
    i = i + 1
    reg_models[[i]] <- as.formula(paste0(outcome, " ~ log(gdp) + log(population) | state + year"))
    
    for (reg in seq(i - 1, i)) {
      reg_results[[reg]] <- fixest::feols(reg_models[[reg]], data = data_munic[state != "PE"][year %in% seq(2014, 2020),])
    }
  }
  
  # Dictionary for variable names
  dict <- c(
    "wavg_delay" = "Average Payment Delay",
    "over_30days" = "\\% Over 30 Days",
    "over_45days" = "\\% Over 45 Days",
    "over_60days" = "\\% Over 60 Days",
    "log(gdp)" = "Log(GDP)",
    "log(population)" = "Log(Population)"
  )
  
  # Create tables
  fixest::setFixest_etable(digits.stats = 2, drop = c("Constant"))
  
  table_a1 <- fixest::etable(reg_results[seq(2, 8, by = 2)], fitstat = c("n", "my", "rmse", "r2", "ar2"), digits = 3, tex = TRUE, dict=dict)
  table_a1 <- c(table_a1[1:10], "\\\\", "  Year Fixed Effects  & \\checkmark  & \\checkmark   & \\checkmark  & \\checkmark \\\\ ", "  State Fixed Effects   & \\checkmark  & \\checkmark   & \\checkmark  & \\checkmark\\\\", "\\midrule \\midrule", table_a1[18:length(table_a1)])
  pdf_table(table_a1, file_name = file.path(table_output, "table_reg_4_columns.tex"))
}

# ---- 5. Regression Analyses Part 2 ----

{
  
  # Deal with outliers 
  cols_to_winsorize <- c("proportion_verification", "proportion_commitment", "proportion_payment")
  data_munic[, (cols_to_winsorize) := lapply(.SD, DescTools::Winsorize, probs = c(0.05, 0.95), na.rm = TRUE), 
             .SDcols = cols_to_winsorize]
  
  # Define regression models
  reg_models <- list(
    proportion_commitment ~ log(gdp) + log(population) + procurement_municipality| year,
    proportion_commitment ~ log(gdp) + log(population) + procurement_municipality| state + year,
    proportion_verification ~ log(gdp) + log(population) + procurement_municipality| year,
    proportion_verification ~ log(gdp) + log(population) + procurement_municipality| state + year,
    proportion_payment ~ log(gdp) + log(population) + procurement_municipality| year,
    proportion_payment ~ log(gdp) + log(population) + procurement_municipality| state + year
  )
  
  # Run regression for each model
  reg_results <- lapply(reg_models, function(model) fixest::feols(model, data = data_munic))
  
  # Variable names and descriptions
  dict <- c(
    "proportion_commitment" = "Commitment (p.p)",
    "proportion_verification" = "Verification (p.p)",
    "proportion_payment" = "Payment (p.p)",
    "log(gdp)" = "Log(GDP)",
    "log(population)" = "Log Population"
  )
  
  # Create tables
  fixest::setFixest_etable(digits.stats = 2, drop = c("Constant"))
  table_a1 <- fixest::etable(
    reg_results,
    title = "Correlation of deviations in percentage points from Treasury Data",
    fitstat = c("n", "my", "rmse", "r2", "ar2"),
    digits = 3,
    tex = TRUE,
    dict = dict
  )
  
  table_a1 <- c(
    table_a1[1:13], 
    "\\\\",
    "  Year Fixed Effects   & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark & \\checkmark \\\\  ",
    "  State Fixed Effects  & \\xmark  & \\checkmark & \\xmark  & \\checkmark & \\xmark  & \\checkmark \\\\  ",
    "\\midrule",
    table_a1[20:length(table_a1)]
  )
  
  pdf_table(table_a1, file_name = file.path(table_output, "reg_deviations.tex"))
  
}
