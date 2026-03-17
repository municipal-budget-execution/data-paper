# code/analysis/fig_deviations_parana.R
# Outputs: Appendix figures: deviation between tender values and commitment values for PR
#   output/figures/histogram_deviations_parana_tender.png
#   output/figures/histogram_deviations_parana_tender_modality.png
#   output/figures/histogram_deviations_parana_tender_munic.png
#
# Input: Data/Intermediate/PR_empenho_licitacao.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

# ---- Load data ----

pr_path <- file.path(intermediate, "PR_empenho_licitacao.csv")
if (!file.exists(pr_path)) {
  message("  --> fig_deviations_parana.R [SKIPPED — PR_empenho_licitacao.csv not found in Data/Intermediate/]")
  quit(save = "no", status = 0)
}

data <- fread(pr_path)

data[valor_corrigido >= 0 & agg_valor_final >= 0,
     deviation := 100 * (valor_corrigido / agg_valor_inicial - 1)]

data <- data[ano_rel >= 2014 & ano_rel <= 2020]
data[, ratio_lic := pmin(deviation, 300)]
data[, modality_group := fcase(
  modalidade %in% c(4L, 5L, 6L), "Auction",
  modalidade == 8L,               "Waiver",
  modalidade == 10L,              "Direct Contracting",
  default = "Other"
)]

# ---- Tender-level overall ----

p_tender <- ggplot(data[deviation >= -100],
                   aes(x = ratio_lic, y = after_stat(width * density))) +
  geom_histogram(binwidth = 10, color = "#0D3446", fill = "#1A476F", alpha = 0.5) +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 0.3) +
  labs(x = "Deviation Tenders - Procurement Commitments", y = "Share") +
  ylim(0, 0.8) +
  theme_classic(base_size = 14) +
  theme(axis.title = element_text(size = 14, face = "bold"),
        axis.text  = element_text(size = 13),
        legend.position = "none")

ggsave(file.path(graph_output, "histogram_deviations_parana_tender.png"),
       p_tender, width = 10, height = 5.625, units = "in", dpi = 300)

# ---- Tender-level by modality ----

data[, modality_group := factor(modality_group,
                                levels = c("Waiver", "Direct Contracting", "Other", "Auction"))]

p_modality <- ggplot(data[deviation >= -100],
                     aes(x = ratio_lic, y = after_stat(width * density))) +
  geom_histogram(binwidth = 10, color = "#0D3446", fill = "#1A476F", alpha = 0.5) +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 0.3) +
  facet_wrap(~ modality_group) +
  labs(x = "Deviation Tenders - Procurement Commitments", y = "Share") +
  ylim(0, 0.8) +
  theme_classic(base_size = 14) +
  theme(axis.title       = element_text(size = 14, face = "bold"),
        axis.text        = element_text(size = 13),
        strip.text       = element_text(size = 9, face = "bold"),
        strip.background = element_blank())

ggsave(file.path(graph_output, "histogram_deviations_parana_tender_modality.png"),
       p_modality, width = 10, height = 5.625, units = "in", dpi = 300)

# ---- Municipality-level ----

munic_agg <- data[, .(sum_lic = sum(valor_corrigido, na.rm = TRUE),
                       sum_com = sum(agg_valor_final,  na.rm = TRUE)),
                  by = .(id_municipio, ano_rel)]
munic_agg[, deviation := 100 * (sum_lic / sum_com - 1)]
munic_agg[, ratio_lic := pmin(deviation, 300)]

p_munic <- ggplot(munic_agg[!is.na(ratio_lic)],
                  aes(x = ratio_lic, y = after_stat(width * density))) +
  geom_histogram(binwidth = 10, color = "#0D3446", fill = "#1A476F", alpha = 0.5) +
  geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 0.3) +
  labs(x = "Deviation Tenders - Procurement Commitments", y = "Share") +
  theme_classic(base_size = 14) +
  theme(axis.title = element_text(size = 14, face = "bold"),
        axis.text  = element_text(size = 13),
        legend.position = "none")

ggsave(file.path(graph_output, "histogram_deviations_parana_tender_munic.png"),
       p_munic, width = 10, height = 5.625, units = "in", dpi = 300)

cat("  Wrote: histogram_deviations_parana_tender.png,",
    "histogram_deviations_parana_tender_modality.png,",
    "histogram_deviations_parana_tender_munic.png\n")
