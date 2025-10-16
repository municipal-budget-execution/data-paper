
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

query = "SELECT id_licitacao_bd, id_municipio, sigla_uf, descricao, valor_total
        FROM `basedosdados.world_wb_mides.licitacao_item`
        WHERE ano = 2021 AND valor_total IS NOT NULL AND id_licitacao_bd IS NOT NULL "
items_query = read_sql(query)
fwrite(items_query,  '/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/mides_2021_items.csv')
