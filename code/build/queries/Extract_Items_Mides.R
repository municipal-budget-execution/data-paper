
# Load libraries
library(tm)
library(wordcloud)
library(SnowballC)
library(basedosdados)
library(stopwords)
library(data.table)
library(ggplot2)
library(basedosdados)
library(dplyr)
library(stringr)

# #Set user's BigQuery billing ID
set_billing_id("projetobd-302617")

query = "SELECT id_licitacao_bd, id_municipio, sigla_uf, descricao, 
CASE 
  WHEN sigla_uf != 'PR' THEN valor_total
  ELSE quantidade_proposta*valor_vencedor
END as valor_item
FROM `basedosdados.world_wb_mides.licitacao_item`
WHERE ano = 2021 AND id_licitacao_bd IS NOT NULL "
items_query = read_sql(query)

items_query = setDT(items_query)[!is.na(valor_item)]
fwrite(items_query,  '/Users/tscot/Dropbox/MiDES-data-paper-replication/Data/Intermediate/mides_2021_items.csv')
