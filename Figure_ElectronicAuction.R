
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
SELECT sigla_uf, ano,modalidade, COUNT(*) AS observation_count 
FROM `basedosdados.world_wb_mides.licitacao` 
GROUP BY sigla_uf, ano, modalidade
"
modalidade <- bq_project_query(project_id_bq, query)
df <- bq_table_download(modalidade)
setDT(df)

df[sigla_uf == "MG"] %>% ggplot() + 
  geom_bar(aes(x = ano, y = observation_count, fill = modalidade),
           stat = "identity", position = "stack") +
  facet_wrap(~sigla_uf)

z = df[modalidade ==6, electronic_auction := observation_count] %>% 
  .[, .(total = sum(observation_count),
        electronic = sum(electronic_auction, na.rm = T)),
    by = .(sigla_uf, ano)] %>% 
  .[, share_electronic := electronic/total]

z[! sigla_uf %in% c('PR', 'CE')] %>% ggplot(aes(x = ano, y = share_electronic, colour = sigla_uf)) + 
  geom_line() + 
  geom_point() + 
  theme_classic()

z %>% ggplot(aes(x = ano, y = total, colour = sigla_uf)) + 
  geom_line() + 
  geom_point() + 
  theme_classic()
