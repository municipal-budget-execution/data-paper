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
 set_billing_id("projetobd-302617")
# 
query = "WITH empenho AS (
  SELECT 
  e.sigla_uf
  ,e.id_municipio
  ,e.id_empenho
  ,e.valor_final
  ,e.valor_inicial
  ,e.ano 
  FROM `basedosdados.world_wb_mides.empenho` e
  WHERE e.sigla_uf = 'PR'
)

, relacionamento AS (
  SELECT 
  r.sigla_uf
  ,r.id_municipio
  ,r.id_empenho
  ,r.id_licitacao
  ,r.ano AS ano_rel
  ,e.valor_final
  ,e.valor_inicial
  ,e.ano AS ano_empenho
  FROM `basedosdados-dev.world_wb_mides.relacionamentos`  r
    INNER JOIN empenho e 
      ON r.sigla_uf = e.sigla_uf 
      AND e.id_municipio = r.id_municipio 
      AND r.id_empenho =  e.id_empenho 
)

, agg AS (
  SELECT 
    sigla_uf
    ,id_municipio
    ,id_licitacao
    ,ano_rel
    ,SUM(valor_final) AS agg_valor_final
    ,SUM(valor_inicial) AS agg_valor_inicial
    ,MIN(ano_empenho) AS min_ano
    ,MAX(ano_empenho) AS max_ano
    ,COUNT(id_empenho) AS number_empenho
  FROM relacionamento 
    GROUP BY sigla_uf, id_municipio, id_licitacao, ano_rel
)

SELECT 
  a.*,
  l.ano, l.sigla_uf, l.id_municipio, l.modalidade, l.valor, l.valor_corrigido, l.valor_orcamento, l.situacao
FROM `basedosdados.world_wb_mides.licitacao` l
LEFT JOIN agg a 
  ON l.ano = a.ano_rel
  AND l.sigla_uf = a.sigla_uf
  AND l.id_municipio = a.id_municipio
  AND l.id_licitacao = a.id_licitacao
WHERE l.sigla_uf = 'PR'
"

items_query = read_sql(query)
fwrite(items_query,  '/Users/tscot/Dropbox/WBER_RR/Data/Compare_Siconfi_Tender/PR_empenho_licitacao')

data = fread('/Users/tscot/Dropbox/WBER_RR/Data/Compare_Siconfi_Tender/PR_empenho_licitacao')

data[valor_corrigido >= 0 & agg_valor_final >= 0, deviation := 100*(valor_corrigido/agg_valor_final - 1)]

##Deviations at licitacao level
data[deviation >= -100] %>% mutate(ratio_lic = pmin(deviation, 200)) %>% ggplot() + 
  geom_histogram(aes(x = ratio_lic,
                     y = stat(width*density)), binwidth = 5, 
                 color = "#0D3446",
                 fill = "#1A476F", alpha = .5) + 
  theme_classic() + 
  geom_vline(xintercept = 0) +
  labs(
    x = "Deviation Tenders - Procurement Commitments",
    y = "Share"
  ) 

##Deviations at licitacao level
data[deviation >= -100] %>% mutate(ratio_lic = pmin(deviation, 200),
                                   modality_group = case_when(
                                     modalidade %in% c(4,5,6) ~ "Auction",
                                     modalidade == 8 ~ "Waiver",
                                     modalidade == 10 ~ "Direct Contraction", 
                                     .default = "Other"
                                   )) %>% 
  ggplot() + 
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
  ) +
  facet_wrap(~ modality_group)


data[deviation >= -100 & deviation <= 200] %>% 
  ggplot() + 
  geom_smooth(aes(x = deviation, y = as.numeric((modalidade %in% c(4,5,6)))), color = 'red') + 
  geom_smooth(aes(x = deviation, y = as.numeric((modalidade == 8))), color = 'blue')



a = data[! is.na(ano_rel)] 
b = data

new = b %>% 
  .[,.(sum_lic = sum(valor_corrigido, na.rm = T),
       sum_com = sum(agg_valor_final, na.rm = T)),
    by = .(id_municipio, ano)] %>% 
  .[,deviation := 100*(sum_lic/sum_com - 1)]

new[deviation >= -200 & deviation <= 200] %>% 
  mutate(ratio_lic = pmin(deviation, 200)) %>% ggplot() + 
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

