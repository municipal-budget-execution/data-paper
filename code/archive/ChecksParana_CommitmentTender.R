library(ggplot2)
library(dplyr)
library(tidyverse)
library(basedosdados)
library(readr)
library(data.table)
library(tibble)
library(patchwork)

path_file = '/Users/tscot/Dropbox/MiDES-data-paper-replication/Data/Intermediate'
path_figures = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures'

#Set user's BigQuery billing ID
#  set_billing_id("projetobd-302617")
# 
# query = "WITH empenho AS (
#   SELECT
#   e.sigla_uf
#   ,e.id_municipio
#   ,e.id_empenho
#   ,e.elemento_despesa
#   ,e.valor_final
#   ,e.valor_inicial
#   ,e.ano
#   FROM `basedosdados.world_wb_mides.empenho` e
#   WHERE e.sigla_uf = 'PR'
# )
# 
# , relacionamento AS (
#   SELECT
#   r.sigla_uf
#   ,r.id_municipio
#   ,r.id_empenho
#   ,r.id_licitacao
#   ,r.ano AS ano_rel
#   ,e.elemento_despesa
#   ,e.valor_final
#   ,e.valor_inicial
#   ,e.ano AS ano_empenho
#   FROM `basedosdados-dev.world_wb_mides.relacionamentos`  r
#     INNER JOIN empenho e
#       ON r.sigla_uf = e.sigla_uf
#       AND e.id_municipio = r.id_municipio
#       AND r.id_empenho =  e.id_empenho
# )
# 
# , agg AS (
#   SELECT
#     sigla_uf
#     ,id_municipio
#     ,id_licitacao
#     ,ano_rel
#     ,MIN(elemento_despesa) AS min_elemento_despesa
#     ,SUM(valor_final) AS agg_valor_final
#     ,SUM(valor_inicial) AS agg_valor_inicial
#     ,MIN(ano_empenho) AS min_ano
#     ,MAX(ano_empenho) AS max_ano
#     ,COUNT(id_empenho) AS number_empenho
#   FROM relacionamento
#     GROUP BY sigla_uf, id_municipio, id_licitacao, ano_rel
# )
# 
# SELECT
#   l.ano, l.sigla_uf, l.id_municipio, l.modalidade, l.valor, l.valor_corrigido, l.valor_orcamento, l.situacao, l.natureza_processo,
#   a.*,
# FROM `basedosdados.world_wb_mides.licitacao` l
# LEFT JOIN agg a
#   ON l.ano = a.ano_rel
#   AND l.sigla_uf = a.sigla_uf
#   AND l.id_municipio = a.id_municipio
#   AND l.id_licitacao = a.id_licitacao
# WHERE l.sigla_uf = 'PR' AND (situacao = '1' OR situacao IS NULL)
# "
# 
# items_query = read_sql(query)
# fwrite(items_query,  paste0(path_file, '/PR_empenho_licitacao.csv'))

data = fread(paste0(path_file, '/PR_empenho_licitacao.csv'))

data[valor_corrigido >= 0 & agg_valor_final >= 0, 
     deviation := 100*(valor_corrigido/agg_valor_inicial - 1)]

data = data %>% 
  filter(ano_rel >= 2014 & ano_rel <= 2020) %>% 
  mutate(ratio_lic = pmin(deviation, 300),
         modality_group = case_when(
                         modalidade %in% c(4,5,6) ~ "Auction",
                         modalidade == 8 ~ "Waiver",
                         modalidade == 10 ~ "Direct Contracting", 
                         .default = "Other"),
         nature_process = case_when(
           natureza_processo %in% c(2,6) ~ "FA",
           .default = "Other")
         )

########Deviations at licitacao level #####

data[deviation >= -100] %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                     y = stat(width*density)), binwidth = 10, 
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) +
  geom_vline(xintercept = 0, , color = 'red', linetype = 'dashed', linewidth = .3) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) +
  ylim(0, 0.8) +
  theme_classic(base_size = 14) +   # increase base font size
  theme(
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 13),
    legend.position = "none"        # remove legend for size
  )
ggsave(filename = paste0(path_figures, '/histogram_deviations_parana_tender.png'),
       width = 10,    # Increase the width
       height = 5.625,    # Keep a standard height
       units = "in",
       dpi = 300)

#stat
data[, .(share_20 = mean(abs(deviation) <= 10, na.rm = T))]

########Deviations at licitacao level - By modality #####
data[deviation >= -100] %>% 
  mutate(modality_group = factor(modality_group,
                levels = c("Waiver", "Direct Contracting",  "Other" , "Auction"))) %>% 
  ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                     y = stat(width*density)), binwidth = 10, 
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) + 
  geom_vline(xintercept = 0, color = 'red', linetype = 'dashed', linewidth = .3) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) +
  ylim(0, 0.8) +
  theme_classic(base_size = 14) +   # increase base font size
  theme(
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 13),
    strip.text = element_text(size = 9, face = "bold"),
    strip.background = element_blank()
  ) +
  facet_wrap(~ modality_group)
ggsave(filename = paste0(path_figures, '/histogram_deviations_parana_tender_modality.png'),
                         width = 10,    # Increase the width
                         height = 5.625,    # Keep a standard height
                         units = "in",
                         dpi = 300)



#Stats by modality
data[! is.na(agg_valor_final), 
     .(share_multiyear = mean((min_ano != max_ano), na.rm = T),
      avg_commits = mean(number_empenho),
      share_FA = mean(nature_process == "FA")), 
    by = .(modality_group)]
#52% of auctions have multiyear commitment vs. 12% of waivers
#Avg number of commitments fr auctions is 34 v. 4 for waivers

# data[deviation >= -100 & deviation <= 200] %>% 
#   ggplot() + 
#   geom_smooth(aes(x = deviation, y = as.numeric((modalidade %in% c(4,5,6)))), color = 'red') + 
#   geom_smooth(aes(x = deviation, y = as.numeric((modalidade == 8))), color = 'blue')


munic_agg = data[,.(sum_lic = sum(valor_corrigido, na.rm = T),
                    sum_com = sum(agg_valor_final, na.rm = T)),
                 by = .(id_municipio, ano)] %>%
  .[,deviation := 100*(sum_lic/sum_com - 1)]

munic_agg %>% 
  mutate(ratio_lic = pmin(deviation, 300)) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                     y = stat(width*density)), binwidth = 10, 
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) + 
  geom_vline(xintercept = 0, color = 'red', linetype = 'dashed', linewidth = .3) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) +
  theme_classic(base_size = 14) +   # increase base font size
  theme(
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 13),
    legend.position = "none"        # remove legend for size
  )
ggsave(filename = paste0(path_figures, '/histogram_deviations_parana_tender_munic.png'),
       width = 10,    # Increase the width
       height = 5.625,    # Keep a standard height
       units = "in",
       dpi = 300)


munic_agg = data[,.(sum_lic = sum(valor_corrigido, na.rm = T),
                    sum_com = sum(agg_valor_final, na.rm = T)),
                 by = .(id_municipio)] %>%
  .[,deviation := 100*(sum_lic/sum_com - 1)]

munic_agg %>% 
  mutate(ratio_lic = pmin(deviation, 300)) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                     y = stat(width*density)), binwidth = 10, 
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) + 
  geom_vline(xintercept = 0, color = 'red', linetype = 'dashed', linewidth = .3) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) +
  theme_classic(base_size = 14) +   # increase base font size
  theme(
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 13),
    legend.position = "none"        # remove legend for size
  )


###ELEMENTO DESPESA
setDT(data)
data[, elemento := substr(as.character(min_elemento_despesa), 5, 7)] %>% 
  .[!is.na(elemento), .(total = .N,
        total_value = sum(agg_valor_final)), by = .(elemento)] %>% 
  mutate(share_N = 100*total/sum(total),
         share_value = 100*total_value/sum(total_value)) %>% 
  arrange(-share_N)

data[, elemento := substr(as.character(min_elemento_despesa), 5, 7)] %>% 
  .[!is.na(elemento), .(total = .N,
                        total_value = sum(agg_valor_final)), by = .(elemento %in% c('30','32', '33','34','35', '36', '37', '38', '39', '51', '52'))] %>% 
  mutate(share_N = 100*total/sum(total),
         share_value = 100*total_value/sum(total_value)) %>% 
  arrange(-share_N)
