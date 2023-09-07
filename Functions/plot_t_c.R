plot_t_c <- function(data, var, title) {
  
  dat <- data %>% 
    filter(!is.na(TREATMENT) & DT_YEAR %in% seq(2016, 2021)) %>% 
    dplyr::group_by(ID_RUT_ISSUER, DT_YEAR, TREATMENT) %>% 
    dplyr::summarise(mean = mean({{var}}, na.rm = TRUE)) %>% 
    dplyr::group_by(DT_YEAR, TREATMENT) %>% 
    dplyr::summarise(mean_effect = mean(mean, na.rm = TRUE),
                     sd_effect   =   sd(mean, na.rm = TRUE),
                     n_effect    =    n()) %>%
    mutate(se_effect = sd_effect / sqrt(n_effect)                             ,
           ci_low = mean_effect - qt(1 - (0.01 / 2), n_effect - 1) * se_effect,
           ci_up  = mean_effect + qt(1 - (0.01 / 2), n_effect - 1) * se_effect)
  
  plot <- ggplot() + 
    geom_hline(yintercept = 30, color = "red", size = 0.3, linetype = "dotted") +
    geom_vline(xintercept = 2019, color = "red", size = 0.5, linetype = "dashed") + 
    geom_errorbar(
      data = dat %>% filter(TREATMENT == "Early Payer"),
      aes(
        x    = DT_YEAR, 
        y    = mean_effect,
        ymin = ci_low,
        ymax = ci_up,
        width = 0.05,
        group = 1
      ), 
      color = "#6F7F94",
      alpha = 0.8,
      size = 1
    )  +
    geom_errorbar(
      data = dat %>% filter(TREATMENT == "Late Payer"),
      aes(
        x    = DT_YEAR, 
        y    = mean_effect,
        ymin = ci_low,
        ymax = ci_up,
        width = 0.05,
        group = 1
      ), 
      color = "#17375E",
      alpha = 0.8,
      size = 1
    ) + 
    geom_line(
      data = dat %>% filter(TREATMENT == "Late Payer"),
      aes(
        x = DT_YEAR      ,
        y = mean_effect),
      color = "#17375E",
      group = 1,
      size = 0.9
    ) + 
    geom_line(
      data = dat %>% filter(TREATMENT == "Early Payer"),
      aes(
        x = DT_YEAR        ,
        y = mean_effect),
      color = "#6F7F94",
      group = 1,
      size = 0.9
    ) + 
    geom_point(
      data = dat %>% filter(TREATMENT == "Late Payer"),
      aes(
        x = DT_YEAR       ,
        y = mean_effect),
      color = "#17375E",
      group = 1,
      size = 3,
      shape = 18) + 
    geom_point(
      data = dat %>% filter(TREATMENT == "Early Payer"),
      aes(
        x = DT_YEAR       ,
        y = mean_effect),
      color = "#6F7F94",
      group = 1,
      size = 3,
      shape = 18) +
    set_theme(
      axis_line_x = element_line(),
      axis_line_y = element_line(),
    ) +
    scale_y_continuous(
      "", 
      breaks = seq(15, 90, by = 15), limits = c(-10, 100)) +
    coord_cartesian(expand = FALSE, clip = 'off') +
    scale_x_continuous(
      "", limits = c(2015.5, 2021.5),
      breaks = seq(2016, 2021)) +
    ggtitle(title)
  
  return(plot)
  
}
