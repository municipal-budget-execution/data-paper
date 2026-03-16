# code/analysis/fig_delay_maps.R
# Outputs: Fig 10 and Fig A5
#   Choropleth maps of payment delay by municipality (2018).
#
# Input files (in Data/Raw/):
#   full_budget_execution_index.csv   — budget data (municipality 7-digit code)
#   region.csv                        — municipality → region lookup
#   BRMUE250GC_SIR.shp               — municipality geometries (CD_GEOCMU)
#   BRUFE250GC_SIR.shp               — state geometries

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("sf", "scales", install = TRUE, character.only = TRUE)

# ---- Load data ----

data_munic <- fread(file.path(input, "full_budget_execution_index.csv"),
                    showProgress = FALSE, encoding = "Latin-1")

data_2018 <- data_munic[year == 2018 & !is.na(wavg_delay)]
data_2018[, over_30days_pct := over_30days * 100]

# Region lookup: columns `region` and `municipality`
region_dt <- fread(file.path(input, "region.csv"))
data_2018  <- merge(data_2018, region_dt, by = "municipality", all.x = TRUE)

# ---- Load local shapefiles ----

mun_sf   <- sf::st_read(file.path(input, "BRMUE250GC_SIR.shp"), quiet = TRUE)
state_sf <- sf::st_read(file.path(input, "BRUFE250GC_SIR.shp"),  quiet = TRUE)

# Municipality code: CD_GEOCMU (character 7-digit) → integer for join
mun_sf$municipality <- as.integer(mun_sf$CD_GEOCMU)

# Merge geometry with budget + region data
map_data <- dplyr::left_join(mun_sf,
                             data_2018[, .(municipality, wavg_delay, over_30days_pct, region)],
                             by = "municipality")

# ---- Define region subsets ----

map_ne <- map_data[!is.na(map_data$region) & map_data$region == "Nordeste", ]
map_ss <- map_data[!is.na(map_data$region) & map_data$region %in% c("Sul", "Sudeste"), ]

# State borders for each region subset via bounding box intersection
bb_ne <- sf::st_bbox(map_ne)
bb_ss <- sf::st_bbox(map_ss)
state_ne <- sf::st_crop(state_sf, bb_ne)
state_ss <- sf::st_crop(state_sf, bb_ss)

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

map_ne$delay_bin  <- bin_var(map_ne$wavg_delay,      delay_breaks)
map_ss$delay_bin  <- bin_var(map_ss$wavg_delay,      delay_breaks)
map_ne$over30_bin <- bin_var(map_ne$over_30days_pct, delay_breaks)
map_ss$over30_bin <- bin_var(map_ss$over_30days_pct, delay_breaks)

# ---- Helper: one-region choropleth ----

choropleth_panel <- function(map_region, state_region, fill_col, legend_title) {
  ggplot() +
    geom_sf(data = map_region, aes(fill = .data[[fill_col]]), color = NA) +
    geom_sf(data = state_region, fill = NA, color = "black", linewidth = 0.3) +
    scale_fill_manual(values   = setNames(delay_colors, delay_labels),
                      na.value = "gray80",
                      name     = legend_title,
                      drop     = FALSE) +
    theme_void() +
    theme(legend.position = "right",
          legend.title    = element_text(size = 9,  family = "LM Roman 10"),
          legend.text     = element_text(size = 8,  family = "LM Roman 10"))
}

# ---- Fig 10: Weighted average delay (days) ----

p_delay <- ggpubr::ggarrange(
  choropleth_panel(map_ne, state_ne, "delay_bin", "Days"),
  choropleth_panel(map_ss, state_ss, "delay_bin", "Days"),
  ncol = 1, nrow = 2, common.legend = TRUE, legend = "right"
)
ggsave(file.path(graph_output, "wavg_delay_2018.pdf"),
       p_delay, width = 8, height = 10, device = cairo_pdf)
ggsave(file.path(graph_output, "wavg_delay_2018.png"),
       p_delay, width = 8, height = 10, bg = "transparent")
ggsave(file.path(graph_output, "Dahis Fig 10.png"),
       p_delay, width = 8, height = 10, bg = "transparent")

# ---- Fig A5: Share of payments > 30 days ----

p_o30 <- ggpubr::ggarrange(
  choropleth_panel(map_ne, state_ne, "over30_bin", "% > 30 days"),
  choropleth_panel(map_ss, state_ss, "over30_bin", "% > 30 days"),
  ncol = 1, nrow = 2, common.legend = TRUE, legend = "right"
)
ggsave(file.path(graph_output, "over30_delay_2018.pdf"),
       p_o30, width = 8, height = 10, device = cairo_pdf)
ggsave(file.path(graph_output, "over30_delay_2018.png"),
       p_o30, width = 8, height = 10, bg = "transparent")
