library(ggplot2)
library(dplyr)
library(tidyverse)
library(basedosdados)
library(readr)
library(data.table)
library(tibble)
library(patchwork)

path_file = '/Users/tscot/Dropbox/WBER_RR/Data/Compare_Siconfi_Tender'
path_figures = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures'
  
#Set user's BigQuery billing ID
# set_billing_id("projetobd-302617")
# 
 query = "WITH commitment AS (
   SELECT
   e.ano
   ,e.sigla_uf
   ,e.id_municipio
   ,ROUND(SUM(CASE WHEN SUBSTR (e.elemento_despesa, 5,2) IN ('30','32', '33','35', '36', '37', '38', '39', '51', '52') THEN valor_final END),2) AS total_compras_empenho
   ,ROUND(SUM(CASE WHEN SUBSTR (e.elemento_despesa, 5,2) IN ('30','32', '33','35', '36', '37', '38', '39', '51', '52') THEN valor_inicial END),2) AS total_compras_empenho_inicial
   ,ROUND(SUM(valor_final),2) AS total_empenho
 FROM basedosdados.world_wb_mides.empenho e
 WHERE e.sigla_uf IN ('PE','PB','MG','CE','PR', 'RS') AND e.ano >= 2010
 GROUP BY 1,2,3
 )

 ,procurement AS (
SELECT
  p.ano
  ,p.sigla_uf
  ,p.id_municipio
  ,ROUND(SUM(p.valor_orcamento),2) AS total_compras_orcamento
  ,ROUND(SUM(p.valor_corrigido),2) AS total_compras_licitacao
FROM basedosdados.world_wb_mides.licitacao p
WHERE situacao = '1' OR situacao IS NULL
GROUP BY 1,2,3
)

,item AS (
SELECT
  i.ano
  ,i.sigla_uf
  ,i.id_municipio
  ,ROUND(SUM(i.valor_total),2) AS total_valor_items
  ,ROUND(SUM(i.valor_vencedor),2) AS total_valor_vencedor
FROM basedosdados.world_wb_mides.licitacao_item i
GROUP BY 1,2,3
)

SELECT
  e.ano
  ,e.sigla_uf
  ,e.id_municipio
  ,e.total_empenho
  ,e.total_compras_empenho
  ,e.total_compras_empenho_inicial
  ,p.total_compras_orcamento
  ,p.total_compras_licitacao
  ,i.total_valor_items
  ,i.total_valor_vencedor
FROM commitment e
LEFT JOIN procurement p ON e.ano = p.ano AND e.sigla_uf = p.sigla_uf AND e.id_municipio = p.id_municipio
LEFT JOIN item i ON e.ano = i.ano AND e.sigla_uf = i.sigla_uf AND e.id_municipio = i.id_municipio
ORDER BY 1,2,3"

items_query = read_sql(query)
fwrite(items_query,  '/Users/tscot/Dropbox/WBER_RR/Data/Compare_Siconfi_Tender/siconfi_compras.csv')

data = fread(paste0(path_file, '/siconfi_compras.csv'))

data = data %>% 
  filter(ano >= 2014 & ano <=2020) %>%  #Most states have procurement data from 2014
  mutate(total_compras_item = pmax(total_valor_items, total_valor_vencedor, na.rm = T)) %>% 
  mutate(ratio_lic  = 100*(total_compras_licitacao/total_compras_empenho-1),
         ratio_item = 100*(total_compras_item/total_compras_empenho-1)) %>% 
  group_by(sigla_uf) %>% 
  mutate(median_state_lic = median(ratio_lic, na.rm = T),
         median_state_item = median(ratio_item, na.rm = T)) %>% 
  ungroup() %>% 
  group_by(ano) %>% 
  mutate(median_year_lic = median(ratio_lic, na.rm = T)) %>% 
  setDT()

median_all = median(data$ratio_lic, na.rm = T)

data %>% mutate(ratio_lic = pmin(ratio_lic, 200)) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                 y = stat(width*density)), binwidth = 5, 
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) + 
  geom_vline(xintercept = median_all, color = 'red', linetype = 'dashed', linewidth = 1) + 
  theme_classic() + 
  geom_vline(xintercept = 0) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) 
ggsave(filename = paste0(path_figures, '/deviations_procurement_all.png'))

data %>%  mutate(ratio_lic = pmin(ratio_lic, 200)) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                    y = stat(width*density)), binwidth = 5,
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) + 
  geom_vline(xintercept = 0) + 
  facet_wrap(~ reorder(sigla_uf, median_state_lic), nrow = 3, ncol = 2) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) +
  theme_classic() +
  theme(
    strip.text = element_text(size = 7, face = "bold"),
    axis.title = element_text(size = 10),
    strip.background = element_blank()
  ) +
  geom_vline(aes(xintercept = median_state_lic), color = 'red', linetype = 'dashed')
ggsave(filename = paste0(path_figures, '/deviations_procurement_states.png'))


data %>% filter(total_compras_empenho > 1e6 & total_compras_licitacao > 1e6) %>%  
  ggplot(aes(x = log(total_compras_empenho), y = log(total_compras_licitacao))) + 
  geom_point(aes(x = log(total_compras_empenho), y = log(total_compras_licitacao)),
             alpha = .1, color = "#1A476F") +  
  geom_line(aes(x = log(total_compras_empenho), y = log(total_compras_empenho)),
            color ="#0D3446") + 
    geom_smooth() + 
  labs(
    x = "Log(Aggregate Tender Value)",
    y = "Log(Aggregate Procurement Commitments)"
  ) +
    theme_classic()
ggsave(filename = paste0(path_figures, '/deviations_procurement_scatter.png'))


  data %>%  mutate(ratio_lic = pmin(ratio_lic, 200)) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                     y = stat(width*density)), binwidth = 5,
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) + 
  geom_vline(xintercept = 0) + 
  facet_wrap(~ ano, nrow = 4, ncol = 2) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) +
  theme_classic() +
  theme(
    strip.text = element_text(size = 7, face = "bold"),
    axis.title = element_text(size = 10),
    strip.background = element_blank()
  )  +
  geom_vline(aes(xintercept = median_year_lic), color = 'red', linetype = 'dashed')
ggsave(filename = paste0(path_figures, '/deviations_procurement_year.png'))


a = lm(log(total_compras_empenho) ~ log(total_compras_licitacao), data = data %>% filter(total_compras_empenho > 1e6 & total_compras_licitacao > 1e6))
summary(a)

##COMparing item and licitacao - overall
data %>% filter(ratio_lic < 200 & ratio_item < 200) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic), bins = 100, alpha = .5, color = 'red') + 
  geom_histogram(aes(x = ratio_item), bins = 100,alpha = .5) + 
  geom_vline(xintercept = median_all, color = 'red', linetype = 'dashed') + 
  theme_classic() + 
  geom_vline(xintercept = 100)

##COMparing item and licitacao - by state
data %>% filter(ratio_lic < 200 & ratio_item < 200) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                     y = stat(width*density)), binwidth = 2, alpha = .5, color = 'red') + 
  geom_histogram(aes(x = ratio_item,
                     y = stat(width*density)), binwidth = 2, alpha = .5) + 
  geom_vline(xintercept = 100) + 
  facet_wrap(~ reorder(sigla_uf, median_state_lic), nrow = 3, ncol = 2) +
  labs(
    x = "Ratio MiDES - SICONFI",
    y = "Share"
  ) +
  theme_classic() +
  theme(
    strip.text = element_text(size = 7, face = "bold"),
    axis.title = element_text(size = 10),
    strip.background = element_blank()
  ) +
  geom_vline(aes(xintercept = median_state_lic), color = 'red', linetype = 'dashed')
