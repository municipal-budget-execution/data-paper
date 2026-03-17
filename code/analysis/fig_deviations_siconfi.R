# code/analysis/fig_deviations_siconfi.R
# Outputs: Appendix figures comparing tender values to procurement commitments
#   output/figures/deviations_procurement_all.png
#   output/figures/deviations_procurement_states.png
#
# Input: Data/Intermediate/siconfi_compras.csv
#   Columns: ano, sigla_uf, id_municipio, total_compras_licitacao,
#             total_compras_empenho, total_compras_item, ...

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

# ---- Load data ----

siconfi_path <- file.path(intermediate, "siconfi_compras.csv")
if (!file.exists(siconfi_path)) {
  message("  --> fig_deviations_siconfi.R [SKIPPED — siconfi_compras.csv not found in Data/Intermediate/]")
  quit(save = "no", status = 0)
}

data <- fread(siconfi_path)

data <- data[ano >= 2014 & ano <= 2020]
data[, total_compras_item := pmax(total_valor_items, total_valor_vencedor, na.rm = TRUE)]
data[, ratio_lic  := 100 * (total_compras_licitacao / total_compras_empenho - 1)]
data[, ratio_item := 100 * (total_compras_item      / total_compras_empenho - 1)]

data[, median_state_lic := median(ratio_lic, na.rm = TRUE), by = sigla_uf]
data[, median_year_lic  := median(ratio_lic, na.rm = TRUE), by = ano]

median_all <- median(data$ratio_lic, na.rm = TRUE)

# ---- Overall distribution ----

data[, ratio_lic_cap := pmin(ratio_lic, 300)]

p_all <- ggplot(data[!is.na(ratio_lic_cap)],
                aes(x = ratio_lic_cap, y = after_stat(width * density))) +
  geom_histogram(binwidth = 10, color = "#0D3446", fill = "#1A476F", alpha = 0.5) +
  geom_vline(xintercept = median_all, color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = 0) +
  labs(x = "Deviation Tenders - Procurement Commitments", y = "Share") +
  ylim(0, 0.12) +
  theme_classic(base_size = 14) +
  theme(axis.title = element_text(size = 14, face = "bold"),
        axis.text  = element_text(size = 13),
        legend.position = "none")

ggsave(file.path(graph_output, "deviations_procurement_all.png"),
       p_all, width = 10, height = 5.625, units = "in", dpi = 300)

# ---- By-state distribution ----

p_states <- ggplot(data[!is.na(ratio_lic_cap)],
                   aes(x = ratio_lic_cap, y = after_stat(width * density))) +
  geom_histogram(binwidth = 10, color = "#0D3446", fill = "#1A476F", alpha = 0.5) +
  geom_vline(xintercept = 0) +
  geom_vline(aes(xintercept = median_state_lic), color = "red", linetype = "dashed") +
  facet_wrap(~ reorder(sigla_uf, median_state_lic), nrow = 3, ncol = 2) +
  labs(x = "Deviation Tenders - Procurement Commitments", y = "Share") +
  ylim(0, 0.12) +
  scale_y_continuous(breaks = c(0, 0.05, 0.10, 0.12)) +
  theme_classic(base_size = 14) +
  theme(axis.title       = element_text(size = 14, face = "bold"),
        axis.text        = element_text(size = 12),
        strip.text       = element_text(size = 9, face = "bold"),
        strip.background = element_blank())

ggsave(file.path(graph_output, "deviations_procurement_states.png"),
       p_states, width = 10, height = 5.625, units = "in", dpi = 300)

cat("  Wrote: deviations_procurement_all.png, deviations_procurement_states.png\n")
