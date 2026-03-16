# code/analysis/fig_noncompetitive_hist.R
# Output: Fig A7 (histogram of share of non-competitive tenders by municipality)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

# ---- Load data ----

data <- fread(file.path(input, "data_histogram_licitacao.csv"))

# ---- Fig A7: Histogram of non-competitive tender share ----

hist_plot <- data[count > 50] |>
  ggplot() +
  geom_histogram(aes(x = share_discretion), bins = 100,
                 color = "#0D3446", fill = "#1A476F") +
  xlab("Share of non-competitive tenders") +
  ylab("Number") +
  theme_classic() +
  theme(
    strip.text  = element_text(size = 7, face = "bold"),
    axis.title  = element_text(size = 11),
    axis.text   = element_text(size = 10)
  )

ggsave(filename = file.path(graph_output, "histogram_noncompetitive.png"),
       hist_plot, width = 8, height = 5)
