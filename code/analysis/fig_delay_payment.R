# code/analysis/fig_delay_payment.R
# Outputs: Fig 9 (histogram + CDF of weighted payment delays)
#          Fig A6 (CDF across years of late payments over 30 days)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

# ---- Load data ----

data_munic <- fread(file.path(input, "full_budget_execution_index.csv"),
                    showProgress = FALSE, encoding = "Latin-1")

home_bias <- fread(file.path(input, "home_bias.csv"))
home_bias <- home_bias[vencedor == 1]
setnames(home_bias, c("municipality", "state", "year", "winner", "same_municipality", "same_state"))
home_bias <- merge(data_munic, home_bias, by = c("municipality", "state", "year"), all.x = TRUE)

# Convert fractions to percentages for all 'over_' variables
home_bias[, (grep("^over_", names(home_bias))) := lapply(.SD, function(x) x * 100),
          .SDcols = grep("^over_", names(home_bias))]

# Exclude PE (no procurement data); restrict to 2014-2020
data_plot <- home_bias[state != "PE"][year %in% 2014:2020]

# ---- Fig 9b: CDF of weighted average payment delay ----

cdf_plot <- ggplot(data_plot, aes(wavg_delay)) +
  stat_ecdf(geom = "line", size = 2, color = "#17375E", linewidth = 1.2) +
  scale_x_continuous("Average Payment Speed (days)", breaks = seq(10, 100, by = 10), limits = c(0, 105)) +
  coord_cartesian(expand = FALSE, clip = "off") +
  scale_y_continuous("", limits = c(0, 1.1), breaks = seq(0.2, 1, by = 0.2)) +
  set_theme(axis_line_x = element_blank(), axis_line_y = element_line(),
            y_text_size = 15, x_text_size = 15, size = 20) +
  ggtitle(label = "Fraction") +
  theme(axis.line.x = element_line(color = "black", size = 0.5),
        axis.ticks.length = unit(0.3, "cm"),
        axis.ticks.x = element_line(),
        axis.text.x = element_markdown(),
        plot.margin = unit(c(0.2, 0.2, 0, 0.1), "lines"),
        strip.background = element_rect(colour = "black", fill = "gray"),
        axis.title.x = element_markdown()) +
  geom_vline(xintercept = 30, color = "black", linewidth = 0.5, linetype = "dashed", alpha = 0.6)

ggsave(filename = file.path(graph_output, "Dahis Fig 9b.png"),
       cdf_plot, width = 14.14, height = 8.51, dpi = 400, units = "in", device = "png")
ggsave(filename = file.path(graph_output, "cdf_sample_wavg_delay_2.jpeg"),
       cdf_plot, width = 14.14, height = 8.51, dpi = 400, units = "in", device = "jpeg")

# ---- Fig 9a: Histogram of weighted average payment delay ----

hist_plot <- ggplot(data_plot, aes(wavg_delay)) +
  geom_histogram(linewidth = 0.8, color = "#0D3446", fill = "#1A476F", alpha = 1, bins = 100) +
  scale_x_continuous("Average Payment Speed (days)", breaks = seq(10, 100, by = 10), limits = c(0, 105)) +
  coord_cartesian(expand = FALSE, clip = "off") +
  scale_y_continuous("") +
  set_theme(axis_line_x = element_blank(), axis_line_y = element_line(),
            y_text_size = 15, x_text_size = 15, size = 20) +
  ggtitle(label = "Density") +
  theme(axis.line.x = element_line(color = "black", size = 0.5),
        axis.ticks.length = unit(0.3, "cm"),
        axis.ticks.x = element_line(),
        axis.text.x = element_markdown(),
        plot.margin = unit(c(0.2, 0.2, 0, 0.1), "lines"),
        strip.background = element_rect(colour = "black", fill = "gray"),
        axis.title.x = element_markdown()) +
  geom_vline(xintercept = 30, color = "black", linewidth = 0.5, linetype = "dashed", alpha = 0.6)

ggsave(filename = file.path(graph_output, "Dahis Fig 9a.png"),
       hist_plot, width = 14.14, height = 8.51, dpi = 400, units = "in", device = "png")
ggsave(filename = file.path(graph_output, "hist_sample_wavg_delay_2.jpeg"),
       hist_plot, width = 14.14, height = 8.51, dpi = 400, units = "in", device = "jpeg")

# ---- Fig A6: CDF across years of late payments over 30 days ----

years <- 2014:2020
plot_list <- vector("list", length(years))

for (i in seq_along(years)) {
  year_plot <- ggplot() +
    scale_x_continuous("", breaks = seq(10, 100, by = 10), limits = c(0, 105)) +
    coord_cartesian(expand = FALSE, clip = "off") +
    scale_y_continuous("") +
    set_theme(axis_line_x = element_blank(), axis_line_y = element_line(),
              y_text_size = 15, x_text_size = 15, size = 20) +
    ggtitle(label = as.character(years[i])) +
    theme(axis.line.x = element_line(color = "black", linewidth = 0.5),
          axis.ticks.length = unit(0.3, "cm"),
          axis.ticks.x = element_line(),
          axis.text.x = element_markdown(),
          plot.title  = element_text(hjust = 0.5, size = 18, color = "black", family = "LM Roman 10"),
          plot.margin = unit(c(0.2, 0.2, 0, 0.1), "lines"),
          strip.background = element_rect(colour = "black", fill = "gray"),
          axis.title.x = element_markdown()) +
    geom_vline(xintercept = 30, color = "black", linewidth = 0.5, linetype = "dashed", alpha = 0.6)

  for (j in 1:i) {
    data_year <- data_plot[data_plot$year == years[j], ]
    year_plot <- year_plot +
      stat_ecdf(data_year, mapping = aes(over_30days), geom = "line",
                size      = ifelse(j == i, 1, 0.5),
                color     = ifelse(j == i, "#17375E", "#6F7F94"),
                alpha     = ifelse(j == i, 1, 0.4),
                linewidth = 0.5)
  }

  plot_list[[i]] <- year_plot
}

combined_plot <- ggpubr::ggarrange(plotlist = plot_list, nrow = 3, ncol = 3, widths = c(0.1, 0.1, 0.1))

ggsave(filename = file.path(graph_output, "cdf_years_over_30days.jpeg"),
       combined_plot, width = 14.14, height = 8.51, dpi = 400, units = "in", device = "jpeg")
