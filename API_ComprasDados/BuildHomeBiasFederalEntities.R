# Packages
library(data.table)
library(janitor)
library(dplyr)
library(numbersBR)
library(stringr)
library(stringi)
library(fixest)
library(ggplot2)
library(ggrepel)   # for clean, non-overlapping labels

# ---- Settings ----
in_dir  = "/Users/tscot/Dropbox/MiDES-data-paper-replication/Data/Intermediate/Transparency_Federal_2021"
raw_dir = "/Users/tscot/Dropbox/MiDES-data-paper-replication/Data/Raw"
path_figures = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures'

#Opening Federal tender data
data_lic = readRDS(paste0(in_dir, '/licitacoes_2021.rds')) %>% setDT()

#Defining municipalities that might be included in our municipal data
municipios = data_lic[uf %in% c('RS', 'PR', 'PE', 'MG', 'PB', 'CE')] %>% 
  .[, .N, by = .(uf, municipio)]
fwrite(municipios, file = paste0(in_dir,'/municipios.csv'))

#Opening items, which include info on winners
data_item = readRDS(paste0(in_dir, '/licitacoes_items_2021.rds')) %>% setDT()

#Only UGs in our sample of interst
data_item_sample = data_item %>% inner_join(data_lic[uf %in% c('RS', 'PR', 'PE', 'MG', 'PB', 'CE'), 
                                              .(municipio = first(municipio),
                                                uf = first(uf)),
                                              by = codigo_ug],
                                     by = 'codigo_ug')

#Unique winners and validate CPF
unique_winners_cnpj = data_item_sample[,.N, by = codigo_vencedor] %>% 
  mutate(valid_cnpj = is.valid(CNPJ(codigo_vencedor))) %>% 
  filter(valid_cnpj == T)

#Takes a while - recover municipality for each CNPJ from RFB database
#unique_winners_cnpj_muni = data.table::merge.data.table(unique_winners_cnpj, items_query,all.x = T,
#                                                        by.x = 'codigo_vencedor', by.y = 'cnpj')

#fwrite(unique_winners_cnpj_muni, file = paste0(in_dir, '/suppliers_munic_federal.csv')

unique_winners_cnpj_muni = fread(paste0(in_dir, '/suppliers_munic_federal.csv'))
nrow(unique_winners_cnpj_muni[is.na(id_municipio)]) #1% we cannot find their CNPJ, likely bc they don't exist anymore

#add info on location of suppliers to item level
data_item_sample = data_item_sample %>% 
  left_join(unique_winners_cnpj_muni %>% mutate(codigo_vencedor = as.character(codigo_vencedor)) %>%
              rename(id_municipio_winner = id_municipio,
                     sigla_uf_winner = sigla_uf) %>% 
              select(codigo_vencedor, id_municipio_winner, sigla_uf_winner),
            by = 'codigo_vencedor')

##Municipality info: recovering municipality code using IBGE data, since in tenderndata we only have NAMES of municipality
munic_code = readxl::read_xls(paste0(raw_dir,'/RELATORIO_DTB_BRASIL_2024_MUNICIPIOS.xls')) %>% 
  clean_names() %>% 
  select(uf, codigo_municipio_completo, nome_municipio)

munic_code = munic_code %>% 
  mutate(municipio = str_to_upper(stri_trans_general(nome_municipio,"Latin-ASCII")))

data_item_sample = data_item_sample %>% 
  mutate(uf_code = as.character(fcase(
    uf == "RS", 43 ,
    uf == "PE", 26 ,
    uf == "PR", 41,
    uf == "CE", 23,
    uf == "PB", 25,
    uf == "MG", 31,
    default = 0))) %>% 
  left_join(munic_code %>% select(municipio,uf, codigo_municipio_completo) %>% rename(uf_code = uf), 
            by = c('municipio', 'uf_code')) %>% 
  mutate(codigo_municipio_completo = ifelse(municipio == "SANTANA DO LIVRAMENTO",4317103 , codigo_municipio_completo)) %>% 
  mutate(same_municipality = case_when(
    codigo_municipio_completo == id_municipio_winner ~ 1,
    codigo_municipio_completo != id_municipio_winner ~ 0,
    is.na(id_municipio_winner) ~ NA_real_),
  same_municipality = as.numeric(same_municipality))
    
rm(data_item, municipios, munic_code, unique_winners_cnpj)


######################################################################################################
################################## BRINGING MIDES DATA ###############################################

#Open Mides data on winners
participante_cnpj <- fread(paste0(in_dir,"/mides_2021_items_alternative_price.csv"))

#Filtering for 2021 and winners, and generating dummy for same municipality
participante_cnpj <- participante_cnpj[ano == 2021 & vencedor == 1] %>%
  mutate(same_municipality = case_when(
      id_municipio == id_municipio_1 ~ 1,
      id_municipio != id_municipio_1 ~ 0,
      is.na(id_municipio_1) ~ NA_real_),
    same_municipality = as.numeric(same_municipality))

#Creating municipality level indicators of local purchases
municipality_share = data_item_sample[!is.na(id_municipio_winner) & !is.na(valor_item), 
                                      .(share_local_federal = mean(same_municipality, na.rm = T), 
                                        share_local_federal_w = weighted.mean(same_municipality, w = valor_item, na.rm = T),
                                        number_federal = .N,
                                        total_federal = sum(valor_item)),by = .(municipio, codigo_municipio_completo)] %>% 
  mutate(id_municipio = as.integer(codigo_municipio_completo)) %>% 
  inner_join(participante_cnpj[!is.na(id_municipio_1) & !is.na(valor_corrigido), 
                              .(share_local_mides = mean(same_municipality, na.rm = T), 
                                share_local_mides_w = weighted.mean(same_municipality, w = valor_corrigido, na.rm = T), 
                                number_mides = .N, 
                                total_mides = sum(valor_corrigido)), by = id_municipio],
             , by = 'id_municipio') %>% 
  mutate(number_total = number_federal + number_mides,
         value_total = total_federal + total_mides)



######################################################################################################
################################## FIGURES AND REGRESSIONS ###############################################



highlights = c("PORTO ALEGRE", "RECIFE", "CURITIBA", "BELO HORIZONTE", 'FORTALEZA', "JOAO PESSOA")
municipality_share[number_federal >= 10 & number_mides >= 10] %>%
  mutate(highlight = ifelse(municipio %in% highlights, "Highlight", "Other")) %>%
  ggplot(aes(x = share_local_mides_w, y = share_local_federal_w)) +
  geom_point(aes(size = value_total,color = highlight), alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +  # replace geom_line diagonal
  geom_text_repel(
    data = municipality_share[municipio %in% highlights],
    aes(label = municipio),
    size = 2.5,
    color = "#E74C3C",
    max.overlaps = 10) +
  scale_color_manual(
    values = c("Highlight" = "#E74C3C", "Other" = "#2C3E50")
  ) +
  labs(
    x = "Share of Local Spending (MIDES)",
    y = "Share of Local Spending (Federal)",
  ) +
  theme_classic(base_size = 14) +   # increase base font size
  theme(
    axis.title = element_text(size = 14, face = "bold"),
    axis.text = element_text(size = 13),
    legend.position = "none"        # remove legend for size
  )  
ggsave(filename = paste0(path_figures, '/scatter_federal_localpurchase.png'),
       width = 10,    # Increase the width
       height = 5.625,    # Keep a standard height
       units = "in",
       dpi = 300)

#Municipal purchases for regressions
dt1 = participante_cnpj %>%
  mutate(municipal = 1,
         modality_group = case_when(
           modalidade %in% c(4,5,6) ~ "Auction",
           modalidade == 8 ~ "Waiver",
           modalidade == 10 ~ "Direct Contracting", 
           .default = "Other")) %>% 
  select(id_municipio,sigla_uf,modality_group,same_municipality, valor_corrigido,municipal)

#Federal purchases for regressions
dt2 = data_item_sample %>% 
  mutate(municipal = 0,
         modality_group = case_when(
           codigo_modalidade_compra %in% c(9999,5) ~ "Auction",
           codigo_modalidade_compra == 8 ~ "Waiver",
           codigo_modalidade_compra == 7 ~ "Direct Contracting",
           .default = "Other")) %>% 
  select(codigo_municipio_completo, uf_code,modality_group, same_municipality, valor_item,municipal) %>% 
  rename(id_municipio = codigo_municipio_completo,
         sigla_uf = uf_code,
         valor_corrigido = valor_item) 

local_regression = rbindlist(list(dt1, dt2)) %>% 
  group_by(id_municipio, municipal) %>% 
  mutate(number = n()) %>% 
  filter(number >= 50 & valor_corrigido >= 0) %>% 
  setDT()
# 
# m1 = feols(same_municipality ~ municipal,
#            data = local_regression)
# m2 = feols(same_municipality ~ municipal,
#            data = local_regression,
#            weights = ~ valor_corrigido)
# m3 = feols(same_municipality ~ municipal | modality_group,
#            data = local_regression)
# m4 = feols(same_municipality ~ municipal | modality_group + id_municipio,
#            data = local_regression)
# m5 = feols(same_municipality ~ municipal | modality_group + id_municipio,
#            data = local_regression,
#            weights = ~ valor_corrigido)

# m1 = feols(same_municipality ~ municipal,
#            data = local_regression)
# m2 = feols(same_municipality ~ municipal | modality_group + id_municipio,
#            data = local_regression)
m1 = feols(same_municipality ~ municipal,
           data = local_regression,
           weights = ~ valor_corrigido)
m2 = feols(same_municipality ~ municipal | modality_group + id_municipio,
           data = local_regression,
           weights = ~ valor_corrigido)

etable( m3, m4)
etable(m1, m2,
       tex = TRUE, 
       file = paste0(path_figures, "/regression_home_bias.tex"),
       dict = c("same_municipality" = "Share Local Purchases","municipal" = "Municipal buyer", "modality_group" = "Modality", "id_municipio" = "Municipality"),
       fitstat = ~ n + r2 + my)


local_regression[, .(share = mean(same_municipality, na.rm = T), 
                     wmean = weighted.mean(same_municipality, w = valor_corrigido, na.rm = T)),
                 by = municipal]
