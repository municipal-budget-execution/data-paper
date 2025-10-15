
# Libraries to run 
library(tidyverse)
library(data.table)
library(basedosdados)
library(bigrquery)
library(readr)

# (This is at the original script by Thiago)
# Set user's BigQuery billing ID 
project_id_bq <- "projetobd-302617" # Removed so PII is not shared 
input_path <- "your/input/path" 

query <- "
SELECT sigla_uf, id_municipio, id_licitacao_bd, descricao_objeto, modalidade, valor_corrigido,valor_orcamento
FROM `basedosdados.world_wb_mides.licitacao` 
WHERE ano = 2021
"
items_query = read_sql(query)
fwrite(items_query,  '/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/mides_2021_tenders.csv')
