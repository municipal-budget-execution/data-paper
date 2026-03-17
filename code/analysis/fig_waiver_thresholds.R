# code/analysis/fig_waiver_thresholds.R
#
# Converted from code/archive/ComparisonMIDES_Federal.do
#
# Outputs:
#   output/figures/Dahis Fig 6a.png              — main paper Fig 6a: bunching histogram
#   output/figures/Dahis Fig 6b.png              — main paper Fig 6b: share of waivers
#   output/figures/distribution_tender_federal.png — appendix
#   output/figures/distribution_items_federal.png  — appendix
#
# Data inputs:
#   Data/Raw/mides_2021_tenders.csv
#   Data/Raw/mides_2021_items.csv
#   Data/Intermediate/Transparency_Federal_2021/licitacoes_2021.csv
#   Data/Intermediate/Transparency_Federal_2021/licitacoes_items_2021.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

in_dir <- file.path(intermediate, "Transparency_Federal_2021")

# ============================================================
# Part 1: Tender-level comparison (waiver threshold figures)
# ============================================================

# ---- MiDES municipal tenders ----
mides <- fread(file.path(bigquery, "mides_2021_tenders.csv"))

mides[, modalidade_group := fcase(
  modalidade == 8L,                        1L,   # Waiver
  modalidade %in% c(4L, 5L, 6L),           2L,   # Auctions
  modalidade == 10L,                        3L,   # Direct Contracting
  modalidade == 2L,                         4L,   # Submission of Prices
  default = 5L                                    # Other
)]
mides[valor_orcamento < 0, valor_orcamento := NA_real_]
mides[, log_amt      := log(valor_orcamento)]
mides[, tender_amount := valor_orcamento]
mides[, federal      := 0L]
mides[is.na(sigla_uf), sigla_uf := "Municipal"]

# ---- Federal tenders from Transparency Portal ----
fed <- fread(file.path(in_dir, "licitacoes_2021.csv"))

fed[, modalidade_group := fcase(
  codigo_modalidade_compra == 6L,               1L,   # Waiver
  codigo_modalidade_compra %in% c(9999L, 9997L, 5L), 2L, # Auctions
  codigo_modalidade_compra == 7L,               3L,   # Direct Contracting
  codigo_modalidade_compra == 2L,               4L,   # Submission of Prices
  default = 5L
)]
setnames(fed, c("valor_licitacao", "objeto"), c("tender_amount", "tender_objective"),
         skip_absent = TRUE)
fed[, log_amt := log(tender_amount)]
fed[, federal := 1L]
fed[, sigla_uf := "Federal"]

# Stack
keep_cols <- c("federal", "sigla_uf", "log_amt", "tender_amount", "modalidade_group")
combined <- rbindlist(
  list(mides[, intersect(keep_cols, names(mides)), with = FALSE],
       fed[,   intersect(keep_cols, names(fed)),   with = FALSE]),
  fill = TRUE
)
combined[, waiver := as.integer(modalidade_group == 1L)]

# Threshold constants
thr <- log(17600)
PALETTE <- c("Federal (Transparency Portal)" = "#00305F",  # dark navy
             "Municipal (MiDES)"              = "#D4632E")  # dark orange

# ---- Fig 6a: Bunching histogram (share of tenders by value bin) ----
bunching_dt <- combined[tender_amount %between% c(2600, 42600) & !is.na(tender_amount)]
bunching_dt[, quantiles := floor((tender_amount - 2600) / 250) * 250 + 2600]
share_dt <- bunching_dt[, .(number = .N), by = .(quantiles, federal)]
share_dt[, tot   := sum(number), by = federal]
share_dt[, share := number / tot]
share_dt[, group_label := fifelse(federal == 1L,
                                  "Federal (Transparency Portal)", "Municipal (MiDES)")]

p_6a <- ggplot(share_dt, aes(x = quantiles, y = share,
                              group = group_label, color = group_label)) +
  geom_line() + geom_point(size = 0.8) +
  geom_vline(xintercept = c(17600, 33000), color = "red", linewidth = 0.4) +
  scale_x_continuous("Estimated tender value (R$)",
                     breaks = c(0, 10000, 17600, 33000),
                     labels = scales::comma) +
  scale_y_continuous("Share of Tenders") +
  scale_color_manual(NULL, values = PALETTE) +
  annotate("text", x = 9200, y = max(share_dt$share, na.rm = TRUE) * 0.9,
           label = "Federal (Transparency Portal)", size = 3.5, color = PALETTE[1]) +
  annotate("text", x = 5200, y = max(share_dt$share, na.rm = TRUE) * 0.15,
           label = "Municipal (MiDES)", size = 3.5, color = PALETTE[2]) +
  theme_classic(base_size = 13) +
  theme(legend.position = "none", panel.grid = element_blank())

ggsave(file.path(graph_output, "Dahis Fig 6a.png"),
       p_6a, width = 10, height = 5, dpi = 300)

# ---- Fig 6b: Share of waivers by tender value bin ----
waiver_dt <- combined[tender_amount %between% c(2600, 42600) & !is.na(tender_amount)]
waiver_dt[, quantiles := floor((tender_amount - 2600) / 500) * 500 + 2600]
waiver_mean <- waiver_dt[, .(waiver = mean(waiver, na.rm = TRUE)), by = .(quantiles, federal)]
waiver_mean[, group_label := fifelse(federal == 1L,
                                     "Federal (Transparency Portal)", "Municipal (MiDES)")]

p_6b <- ggplot(waiver_mean, aes(x = quantiles, y = waiver,
                                 group = group_label, color = group_label)) +
  geom_line(linewidth = 0.9) + geom_point(size = 1) +
  geom_vline(xintercept = c(17600, 33000), color = "red", linewidth = 0.4) +
  scale_x_continuous("Estimated tender value (R$)",
                     breaks = c(0, 10000, 17600, 33000),
                     labels = scales::comma) +
  scale_y_continuous("Share of Waivers", limits = c(0, 1),
                     labels = scales::percent_format(accuracy = 1)) +
  scale_color_manual(NULL, values = PALETTE) +
  annotate("text", x = 5200, y = 0.85,
           label = "Federal (Transparency Portal)", size = 3.5, color = PALETTE[1]) +
  annotate("text", x = 5200, y = 0.56,
           label = "Municipal (MiDES)", size = 3.5, color = PALETTE[2]) +
  theme_classic(base_size = 13) +
  theme(legend.position = "none", panel.grid = element_blank())

ggsave(file.path(graph_output, "Dahis Fig 6b.png"),
       p_6b, width = 10, height = 5, dpi = 300)

# ---- Appendix: KDE of log tender values ----
kde_dt <- combined[tender_amount >= 100 & !is.na(log_amt)]

states_shade <- c("CE", "MG", "PB", "PE", "PR", "RS")
p_kde <- ggplot() +
  # state-level shaded densities
  {
    lapply(states_shade, function(s) {
      geom_density(data = kde_dt[sigla_uf == s],
                   aes(x = log_amt),
                   color = "gray70", fill = NA, alpha = 0.2, linetype = "dashed")
    })
  } +
  geom_density(data = kde_dt[federal == 1L],
               aes(x = log_amt), color = PALETTE[1], linewidth = 1.2) +
  geom_density(data = kde_dt[federal == 0L],
               aes(x = log_amt), color = PALETTE[2], linewidth = 1.2) +
  geom_vline(xintercept = thr, color = "red", linewidth = 0.5) +
  annotate("text", x = 7,  y = 0.22, label = "Federal (Transparency Portal)",
           size = 2.8, color = PALETTE[1]) +
  annotate("text", x = 15, y = 0.15, label = "Municipal (MiDES)",
           size = 2.8, color = PALETTE[2]) +
  labs(x = "Log(Tender Value)", y = "Density") +
  theme_classic(base_size = 13) +
  theme(legend.position = "none", panel.grid = element_blank())

ggsave(file.path(graph_output, "distribution_tender_federal.png"),
       p_kde, width = 10, height = 5, dpi = 300)

# ============================================================
# Part 2: Item-level comparison
# ============================================================

items_mides <- fread(file.path(bigquery, "mides_2021_items.csv"))
items_mides[, federal := 0L]

items_fed <- fread(file.path(in_dir, "licitacoes_items_2021.csv"))
items_fed[, federal := 1L]
# Drop PR from MiDES (per original do file)
items_mides <- items_mides[sigla_uf != "PR"]

keep_items  <- c("federal", "sigla_uf", "valor_item")
items_stack <- rbindlist(
  list(items_mides[, intersect(keep_items, names(items_mides)), with = FALSE],
       items_fed[,   intersect(keep_items, names(items_fed)),   with = FALSE]),
  fill = TRUE
)
items_stack[, log_amt := log(valor_item)]

# 20% sample for density (mirrors original do file)
set.seed(123)
n_sample   <- ceiling(nrow(items_stack) * 0.20)
idx_sample <- sample(nrow(items_stack), n_sample)
items_samp <- items_stack[idx_sample][valor_item >= 10 & !is.na(log_amt)]

states_shade_items <- c("CE", "MG", "RS")
p_items <- ggplot() +
  {
    lapply(states_shade_items, function(s) {
      geom_density(data = items_samp[sigla_uf == s],
                   aes(x = log_amt),
                   color = "gray70", fill = NA, linetype = "dashed")
    })
  } +
  geom_density(data = items_samp[federal == 1L],
               aes(x = log_amt), color = PALETTE[1], linewidth = 1.2) +
  geom_density(data = items_samp[federal == 0L],
               aes(x = log_amt), color = PALETTE[2], linewidth = 1.2) +
  annotate("text", x = 11, y = 0.18, label = "Federal (Transparency Portal)",
           size = 2.8, color = PALETTE[1]) +
  annotate("text", x = 3,  y = 0.18, label = "Municipal (MiDES)",
           size = 2.8, color = PALETTE[2]) +
  labs(x = "Log(Item Value)", y = "Density") +
  theme_classic(base_size = 13) +
  theme(legend.position = "none", panel.grid = element_blank())

ggsave(file.path(graph_output, "distribution_items_federal.png"),
       p_items, width = 10, height = 5, dpi = 300)

cat("  Wrote: Dahis Fig 6a.png, Dahis Fig 6b.png,",
    "distribution_tender_federal.png, distribution_items_federal.png\n")
