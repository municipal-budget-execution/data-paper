# code/analysis/fig_scatter_delay_gdp.R
# Output: Fig 11 (binned scatter: average payment speed vs. log GDP per capita)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))
source(here::here("code/utils/set_theme_ggplots.R"))

pacman::p_load("binsreg", install = TRUE, character.only = TRUE)

# ---- Load data ----

data_munic <- fread(file.path(input, "full_budget_execution_index.csv"),
                    showProgress = FALSE, encoding = "Latin-1")

home_bias <- fread(file.path(input, "home_bias.csv"))
home_bias <- home_bias[vencedor == 1]
setnames(home_bias, c("municipality", "state", "year", "winner", "same_municipality", "same_state"))
home_bias <- merge(data_munic, home_bias, by = c("municipality", "state", "year"), all.x = TRUE)

home_bias[, (grep("^over_", names(home_bias))) := lapply(.SD, function(x) x * 100),
          .SDcols = grep("^over_", names(home_bias))]

data_plot <- home_bias[state != "PE"][year %in% 2014:2020]

# ---- Fig 11: Binned scatter of payment speed vs. log GDP per capita ----

data_plot[, log_gdp := log(gdp_per_capita)]

binreg_object <- binsglm(data = data_plot, y = wavg_delay, x = log_gdp, randcut = 1, polyreg = 1)

binreg_plot <- binreg_object[["bins_plot"]] +
  scale_x_continuous("Log (GDP per capita)") +
  ggtitle("Average Payment Speed (days)") +
  coord_cartesian(expand = FALSE, clip = "off") +
  scale_y_continuous("", limits = c(14, 24), breaks = seq(15, 23, by = 1)) +
  set_theme(axis_line_x = element_line(), axis_line_y = element_line())

ggsave(filename = file.path(graph_output, "scatter_plot.jpeg"),
       binreg_plot, width = 14.14, height = 8.51, dpi = 400, units = "in", device = "jpeg")
