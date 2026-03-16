# code/analysis/fig_delay_maps.R
# Outputs: Fig 10 and Fig A5
#   Choropleth maps of payment delay by municipality (2018).
#   - Fig 10:  wavg_delay (weighted average delay in days)
#   - Fig A5:  over_30days (% payments delayed > 30 days)
#   Two-panel layout: Northeast vs. South/Southeast.
#
# Input CSV (pre-downloaded by code/build/ingest_bigquery.R):
#   full_budget_execution_index.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("sf", "geobr", "scales", install = TRUE, character.only = TRUE)

# ---- Load budget execution data ----

data_munic <- fread(file.path(input, "full_budget_execution_index.csv"),
                    showProgress = FALSE, encoding = "Latin-1")

data_2018 <- data_munic[year == 2018 & !is.na(wavg_delay)]
data_2018[, over_30days := over_30days * 100]

# ---- Load municipality and state geometries via geobr ----

mun_sf   <- geobr::read_municipality(year = 2010, showProgress = FALSE)
state_sf <- geobr::read_state(year = 2010, showProgress = FALSE)

# Standardise municipality code key (7-digit)
mun_sf <- dplyr::rename(mun_sf, municipality = code_muni)

# Merge geometries with budget data
map_data <- dplyr::left_join(mun_sf,
                             data_2018[, .(municipality, wavg_delay, over_30days)],
                             by = "municipality")

# ---- Define region subsets ----

NE_STATES <- c("CE", "MA", "PI", "RN", "PB", "PE", "AL", "SE", "BA")
SS_STATES <- c("SP", "RJ", "ES", "MG", "PR", "SC", "RS")

map_ne <- map_data[map_data$abbrev_state %in% NE_STATES, ]
map_ss <- map_data[map_data$abbrev_state %in% SS_STATES, ]

state_ne <- state_sf[state_sf$abbrev_state %in% NE_STATES, ]
state_ss <- state_sf[state_sf$abbrev_state %in% SS_STATES, ]

# ---- Discrete colour bins ----

delay_breaks <- c(1, 12, 18, 24, 30, 38, 48, 70, 85, 100)
delay_colors <- c("#f0f9e8", "#ccebc5", "#a8ddb5", "#7bccc4",
                  "#4eb3d3", "#2b8cbe", "#0868ac", "#084081", "#191970")

delay_labels <- paste0(delay_breaks[-length(delay_breaks)], "–",
                       delay_breaks[-1])

bin_var <- function(x, breaks) {
  cut(x, breaks = breaks, include.lowest = TRUE,
      labels = paste0(breaks[-length(breaks)], "–", breaks[-1]))
}

map_ne$delay_bin   <- bin_var(map_ne$wavg_delay, delay_breaks)
map_ss$delay_bin   <- bin_var(map_ss$wavg_delay, delay_breaks)
map_ne$over30_bin  <- bin_var(map_ne$over_30days, delay_breaks)
map_ss$over30_bin  <- bin_var(map_ss$over_30days, delay_breaks)

# ---- Helper: one-region choropleth ----

choropleth_panel <- function(map_region, state_region, fill_col, title) {
  ggplot() +
    geom_sf(data = map_region, aes(fill = .data[[fill_col]]), color = NA) +
    geom_sf(data = state_region, fill = NA, color = "black", linewidth = 0.4) +
    scale_fill_manual(values  = setNames(delay_colors, delay_labels),
                      na.value = "gray80",
                      name    = title,
                      drop    = FALSE) +
    theme_void() +
    theme(legend.position  = "right",
          legend.title     = element_text(size = 9, family = "LM Roman 10"),
          legend.text      = element_text(size = 8, family = "LM Roman 10"),
          plot.title       = element_text(hjust = 0.5, size = 10, family = "LM Roman 10"))
}

# ---- Fig 10: Weighted average delay ----

p_ne_delay <- choropleth_panel(map_ne, state_ne, "delay_bin", "Days")
p_ss_delay <- choropleth_panel(map_ss, state_ss, "delay_bin", "Days")

p_delay <- ggpubr::ggarrange(p_ne_delay, p_ss_delay,
                              ncol = 1, nrow = 2, common.legend = TRUE, legend = "right")

ggsave(file.path(graph_output, "wavg_delay_2018.pdf"),
       p_delay, width = 8, height = 10, device = cairo_pdf)
ggsave(file.path(graph_output, "wavg_delay_2018.png"),
       p_delay, width = 8, height = 10, bg = "transparent")

# ---- Fig A5: Share over 30 days ----

p_ne_o30 <- choropleth_panel(map_ne, state_ne, "over30_bin", "% > 30 days")
p_ss_o30 <- choropleth_panel(map_ss, state_ss, "over30_bin", "% > 30 days")

p_o30 <- ggpubr::ggarrange(p_ne_o30, p_ss_o30,
                            ncol = 1, nrow = 2, common.legend = TRUE, legend = "right")

ggsave(file.path(graph_output, "over30_delay_2018.pdf"),
       p_o30, width = 8, height = 10, device = cairo_pdf)
ggsave(file.path(graph_output, "over30_delay_2018.png"),
       p_o30, width = 8, height = 10, bg = "transparent")
