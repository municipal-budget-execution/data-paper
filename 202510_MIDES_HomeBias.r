################################################################################
### MIDES Project - Review and translate code from Python to R
### Author: Fernanda Garcia
### October 2025
### Based on original code by Thiago Scot 
################################################################################

# Libraries to run 
library(tidyverse)
library(basedosdados)
library(readr)
library(data.table)
library(tibble)
library(patchwork)


################### 0. EXTRACT FROM BQ #####################

# (This is at the original script by Thiago)
# Set user's BigQuery billing ID 
# project_id_bq <- "your_project_id" # Removed so PII is not shared 
# input_path <- "your/input/path" 

query <- "
SELECT
    a.*, l.modalidade, b.data, b.cnpj, b.id_municipio, b.data_inicio_atividade,
    b.sigla_uf, b.cnpj_basico, b.identificador_matriz_filial, s.opcao_simples, s.opcao_mei
FROM (
    SELECT *
    FROM `basedosdados.world_wb_mides.licitacao_participante`
    WHERE id_licitacao_bd IS NOT NULL
  ) a
LEFT JOIN (
    SELECT modalidade, id_licitacao_bd
    FROM `basedosdados.world_wb_mides.licitacao`
    WHERE id_licitacao_bd IS NOT NULL
  ) l
ON a.id_licitacao_bd = l.id_licitacao_bd
LEFT JOIN (
    SELECT
        CAST(cnpj AS STRING) AS cnpj,
        cnpj_basico,
        id_municipio,
        sigla_uf,
        identificador_matriz_filial,
        data_inicio_atividade,
        MAX(data) AS data
    FROM
        `basedosdados.br_me_cnpj.estabelecimentos`
    GROUP BY
        cnpj,
        cnpj_basico,
        id_municipio,
        sigla_uf,
        data_inicio_atividade,
        identificador_matriz_filial
) b ON CAST(a.documento AS STRING) = b.cnpj
LEFT JOIN
    `basedosdados.br_me_cnpj.simples` s ON b.cnpj_basico = s.cnpj_basico
WHERE
    a.tipo = '1'
"

# run_query_and_save_results <- function() {
#   participante_cnpj <- bq_project_query(project_id_bq, query)
#   df <- bq_table_download(participante_cnpj)
#   write_csv(df, file.path(input_path, "participante_cnpj.csv"), na = "", append = FALSE)
# }
# 
# if (run_query == TRUE) {
#   run_query_and_save_results()
# }

#########################################################################################################################
################################      1. CLEANING DATA.   ##########################################
#########################################################################################################################

# Participant and population data
participante_cnpj <- fread("/Users/tscot/Library/CloudStorage/OneDrive-WBG/Pckage_Mides/participante_cnpj.csv")
population <- fread("/Users/tscot/Library/CloudStorage/OneDrive-WBG/Pckage_Mides/population.csv")

nrow(participante_cnpj[vencedor == 1, .N, by = .(cnpj_basico)])
#--- Same municipality ---------------------------------------------------------
participante_cnpj <- participante_cnpj %>%
  mutate(
    same_municipality = case_when(
      id_municipio == id_municipio_1 ~ 1,
      id_municipio != id_municipio_1 ~ 0,
      is.na(id_municipio_1) ~ NA_real_
    ),
    same_municipality = as.numeric(same_municipality)
  )

#--- Same state ----------------------------------------------------------------
participante_cnpj <- participante_cnpj %>%
  mutate(
    same_state = case_when(
      sigla_uf == sigla_uf_1 ~ 1,
      sigla_uf != sigla_uf_1 ~ 0,
      is.na(cnpj) ~ NA_real_
    ),
    same_state = as.numeric(same_state)
  )

#--- Firm age ------------------------------------------------------------------
participante_cnpj <- participante_cnpj %>%
  mutate(
    ano_inicio_atividade = str_sub(as.character(data_inicio_atividade), 1, 4),
    ano_inicio_atividade = str_replace(ano_inicio_atividade, "NaT", "-100"),
    idade_firma = if_else(
      ano_inicio_atividade == "-100",
      NA_real_,
      as.numeric(ano) - as.numeric(ano_inicio_atividade)
    )
  )


#--- Non-competitive tenders ---------------------------------------------------
participante_cnpj <- participante_cnpj %>%
  mutate(
    licitacao_discricionaria = case_when(
      is.na(modalidade) ~ NA_real_,
      modalidade %in% c("8", "10") ~ 1,
      TRUE ~ 0
    )
  )

#--- SMEs ----------------------------------------------------------------------
participante_cnpj <- participante_cnpj %>%
  mutate(
    firma_sme = if_else(
      opcao_simples == "1" | opcao_mei == "1", 1, 0, missing = 0 
    )
  )


#--- Drop duplicates (keep first) ----------------------------------------------
#   (Keeps the first row encountered for each (id_licitacao_bd, cnpj))
participante_cnpj <- participante_cnpj %>%
  distinct(id_licitacao_bd, cnpj, .keep_all = TRUE)
sum(duplicated(participante_cnpj[, c("id_licitacao_bd", "cnpj")])) # 0

#--- Filter years ---------------------------------------------------------------
participante_cnpj <- participante_cnpj %>% 
  filter(ano >= 2014)

#--- Format types ---------------------------------------------------------------
participante_cnpj <- participante_cnpj %>%
  mutate(
    vencedor = as.integer(vencedor),
    same_municipality = as.numeric(same_municipality),
    same_state = as.numeric(same_state),
    idade_firma = as.numeric(idade_firma)
  )



#########################################################################################################################
################################      2. FIGURES   ##########################################
#########################################################################################################################

###############################.   2.1 STATE LEVEL.  ####################################################################

#--- Home bias by state and by competition -------------------------------------
# home_bias: group by id_municipio, sigla_uf, vencedor and calculate means
home_bias <- participante_cnpj %>%
  .[, .(same_municipality = mean(same_municipality, na.rm = TRUE),
             same_state = mean(same_state, na.rm = TRUE),
             same_municipality_w = weighted.mean(same_municipality,w = valor_corrigido, na.rm = TRUE),
             same_state_w = weighted.mean(same_state,  w = valor_corrigido, na.rm = TRUE)),
    by = .(id_municipio, sigla_uf, vencedor)]

home_bias[, ":=" (average_state = mean(same_municipality),
                  average_state_w = mean(same_municipality_w, na.rm = T)), by = .(sigla_uf, vencedor)]

#Home bias by state
# Home bias by state - edited
ufs <- c("MG", "PR", "RS", "PB", "CE", "PE")
vencedores_ufs <- home_bias %>%
  filter(vencedor == 1, sigla_uf %in% ufs)

mean_df <- vencedores_ufs %>%
  group_by(sigla_uf) %>%
  summarise(average_state = first(average_state, na.rm = TRUE),
            average_state_w = first(average_state_w, na.rm = TRUE),)


######################## FIGURE 6 PAPER: WEIGHTED ######################## 
ggplot(vencedores_ufs, aes(x = same_municipality_w)) +
  geom_histogram(aes(y = stat(width*density)), binwidth = .025,
                 color = "#0D3446",
                 fill = "#1A476F", linewidth = 0.5) +
  geom_vline(aes(xintercept = average_state_w), 
             color = "red", linetype = "dashed", linewidth = .5) +
  geom_text(
    data = mean_df, 
    aes(x = average_state_w + 0.02 , y = Inf, label = sprintf("%.2f", average_state_w)),
    color = "red", hjust = 0, vjust = 2, size = 2
  ) +
  facet_wrap(~ reorder(sigla_uf, average_state_w), nrow = 3, ncol = 2) +
  scale_x_continuous(limits = c(0, 0.7)) +
  labs(
    x = "Share of same-municipality purchases",
    y = "Share"
  ) +
  theme_classic() +
  theme(
    strip.text = element_text(size = 7, face = "bold"),
    axis.title = element_text(size = 10),
    strip.background = element_blank()
  )
ggsave(filename = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/home_bias_by_state_weighted.png')



######################## FIGURE A PAPER: Unweighted. ######################## 

ggplot(vencedores_ufs, aes(x = same_municipality)) +
  geom_histogram(aes(y = stat(width*density)), binwidth = .025,
                 color = "#0D3446",
                 fill = "#1A476F", linewidth = 0.5) +
  geom_vline(aes(xintercept = average_state), 
             color = "red", linetype = "dashed", linewidth = .5) +
  geom_text(
    data = mean_df, 
    aes(x = average_state + 0.02 , y = Inf, label = sprintf("%.2f", average_state)),
    color = "red", hjust = 0, vjust = 2, size = 2
  ) +
  facet_wrap(~ reorder(sigla_uf, average_state), nrow = 3, ncol = 2) +
  scale_x_continuous(limits = c(0, 0.7)) +
  labs(
    x = "Share of same-municipality suppliers",
    y = "Share"
  ) +
  theme_classic() +
  theme(
    strip.text = element_text(size = 7, face = "bold"),
    axis.title = element_text(size = 10),
    strip.background = element_blank()
  )
ggsave(filename = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/home_bias_by_state_unw.png')

#Table for referees: comparing weighted vs. unweighted by state
a = vencedores_ufs[, .(unweighted = round(100*first(average_state), 2),
                       weighted = round(100*first(average_state_w), 2)),
                   by = .(sigla_uf)]

###############################.   2.2 COMPETITIVE VS NON-COMPETITIVE LEVEL.  ####################################################################


# home_bias_competition: group by id_municipio, sigla_uf, vencedor, 
# licitacao_discricionaria and calculate means
home_bias_competition <- participante_cnpj %>%
  .[, .(number = .N,
        same_municipality = mean(same_municipality, na.rm = TRUE),
        same_state = mean(same_state, na.rm = TRUE),
        same_municipality_w = weighted.mean(same_municipality,w = valor_corrigido, na.rm = TRUE),
        same_state_w = weighted.mean(same_state,  w = valor_corrigido, na.rm = TRUE)),
    by = .(licitacao_discricionaria, id_municipio,vencedor)]

home_bias_competition[, ":=" (average_modality = mean(same_municipality),
                              average_modality_w = mean(same_municipality_w, na.rm = T),
                              type_string = fcase(
                                licitacao_discricionaria ==1, "Non-competitive tender",
                                licitacao_discricionaria ==0, "Competitive tender",
                                is.na(licitacao_discricionaria), NA)), 
                  by = .(vencedor, licitacao_discricionaria)]


# vencedores1 <- home_bias_competition %>%
#   filter(vencedor == 1 & licitacao_discricionaria == 0)
# 
# media_vencedores1 <- mean(vencedores1$same_municipality, na.rm = TRUE)
# vencedores1 <- vencedores1 %>% mutate(tender_type = "Competitive tender")
# 
# vencedores2 <- home_bias_competition %>%
#   filter(vencedor == 1 & licitacao_discricionaria == 1)
# media_vencedores2 <- mean(vencedores2$same_municipality, na.rm = TRUE)
# vencedores2 <- vencedores2 %>% mutate(tender_type = "Non-competitive tender")
# 
# plot_data <- bind_rows(vencedores1, vencedores2)
# 
# mean_df <- tibble(
#   tender_type = c("Competitive tender", "Non-competitive tender"),
#   mean_val = c(media_vencedores1, media_vencedores2)
# )


vencedores_modality <- home_bias_competition %>%
  filter(vencedor == 1 & !is.na(licitacao_discricionaria)) 

mean_df <- vencedores_modality %>%
  group_by(type_string) %>%
  summarise(average_modality = first(average_modality, na.rm = TRUE),
            average_modality_w = first(average_modality_w, na.rm = TRUE))


######################## FIGURE A PAPER: UNWEIGHTED ######################## 

ggplot(vencedores_modality, aes(x = same_municipality)) +
  geom_histogram(aes(y = stat(width*density)), binwidth = .025,
                 color = "#0D3446", fill = "#1A476F", linewidth = 0.5
  ) +
  geom_vline(
    aes(xintercept = average_modality),
    color = "red", linetype = "dashed", linewidth = 0.5
  ) +
  geom_text(
    data = mean_df,
    aes(x = average_modality + 0.01, y = Inf, label = sprintf("%.2f", average_modality)),
    color = "red", hjust = 0, vjust = 2, size = 3
  ) +
  facet_wrap(~ type_string, ncol = 1,) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(
    x = "Share of same-municipality suppliers",
    y = "Frequency"
  ) +
  theme_classic() +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(face = "bold")
  )
ggsave(filename = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/home_bias_by_type_unw.png')

######################## FIGURE 7 PAPER: UNWEIGHTED ######################## 

ggplot(vencedores_modality, aes(x = same_municipality_w)) +
  geom_histogram(aes(y = stat(width*density)), binwidth = .025,
                 color = "#0D3446", fill = "#1A476F", linewidth = 0.5
  ) +
  geom_vline(
    aes(xintercept = average_modality_w),
    color = "red", linetype = "dashed", linewidth = 0.5
  ) +
  geom_text(
    data = mean_df,
    aes(x = average_modality_w + 0.01, y = Inf, label = sprintf("%.2f", average_modality_w)),
    color = "red", hjust = 0, vjust = 2, size = 3
  ) +
  facet_wrap(~ type_string, ncol = 1,) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(
    x = "Share of same-municipality suppliers",
    y = "Frequency"
  ) +
  theme_classic() +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(face = "bold")
  )
ggsave(filename = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/home_bias_by_type_weighted.png')


###############################.   2.3 ABOVE VS. BELOW MEDIAN POPULATION LEVEL.  ####################################################################

#--- Population median per year, pick 2018, drop cols --------------------------
population <- population %>%
  mutate(populacao = as.numeric(populacao)) %>% 
  group_by(ano) %>%
  mutate(median_pop = median(populacao, na.rm = TRUE)) %>%
  ungroup()

population <- population %>%
  mutate(ano = as.integer(ano),
         id_municipio = as.character(id_municipio)) %>%   
  filter(ano == 2018) %>%             
  select(-ano, -sigla_uf)

#--- Merge (left) and flag above/below median ----------------------------------
home_bias$id_municipio <- as.character(home_bias$id_municipio)

home_bias_pop <- home_bias %>%
  left_join(population, by = "id_municipio") %>%
  mutate(
    pop_above_median = if_else(populacao > median_pop, 1L, 0L)
  )
home_bias_pop[, ":=" (average_population = mean(same_municipality),
                      average_population_w = mean(same_municipality_w, na.rm = T),
                      type_string = fcase(
                        pop_above_median ==1, "Population Above Median",
                        pop_above_median ==0, "Population Below Median")), 
                      by = .(vencedor, pop_above_median)]


#### Figures 

vencedores_population <- home_bias_pop %>%
  filter(vencedor == 1) 

mean_df <- vencedores_population %>%
  group_by(type_string) %>%
  summarise(average_population = first(average_population, na.rm = TRUE),
            average_population_w = first(average_population_w, na.rm = TRUE))



######################## FIGURE A PAPER: UNWEIGHTED ######################## 

ggplot(vencedores_population, aes(x = same_municipality)) +
  geom_histogram(aes(y = stat(width*density)), binwidth = .025,
                 color = "#0D3446", fill = "#1A476F", linewidth = 0.5
  ) +
  geom_vline(
    aes(xintercept = average_population),
    color = "red", linetype = "dashed", linewidth = 0.5
  ) +
  geom_text(
    data = mean_df,
    aes(x = average_population + 0.02, y = Inf, label = sprintf("%.2f", average_population)),
    color = "red", hjust = 0, vjust = 2, size = 2
  ) +
  facet_wrap(~ type_string, ncol = 1,) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(
    x = "Share of same-municipality suppliers",
    y = "Frequency"
  ) +
  theme_classic() +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(face = "bold")
  )
ggsave(filename = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/home_bias_population_unw.png')

######################## FIGURE 7 PAPER: UNWEIGHTED ######################## 

ggplot(vencedores_population, aes(x = same_municipality_w)) +
  geom_histogram(aes(y = stat(width*density)), binwidth = .025,
                 color = "#0D3446", fill = "#1A476F", linewidth = 0.5
  ) +
  geom_vline(
    aes(xintercept = average_population_w),
    color = "red", linetype = "dashed", linewidth = 0.5
  ) +
  geom_text(
    data = mean_df,
    aes(x = average_population_w + 0.01, y = Inf, label = sprintf("%.2f", average_population_w)),
    color = "red", hjust = 0, vjust = 2, size = 2
  ) +
  facet_wrap(~ type_string, ncol = 1,) +
  scale_x_continuous(limits = c(0, 1)) +
  labs(
    x = "Share of same-municipality purchases",
    y = "Frequency"
  ) +
  theme_classic() +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(face = "bold")
  )
ggsave(filename = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/home_bias_population_weighted.png')


###New scatter plot
ggplot(vencedores_population, aes(x = log(populacao))) +
  geom_smooth(method = 'loess', aes(y = same_municipality), color = "#0D3446" ) + 
  geom_smooth(method = 'loess', aes(y = same_municipality_w), color = "red") +
  scale_x_continuous(limits = c(6,13.81)) +
  labs(
    y = "Share from same-municipality",
    x = "Log(population)"
  ) +
  annotate("text", x=8, y=.28, label= "Share of purchases", color = 'red') + 
  annotate("text", x=8.5, y=.15, label= "Share of suppliers", color = "#0D3446") + 
  theme_classic() +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(face = "bold"),
    axis.text=element_text(size=12),
    axis.title = element_text(size=12)
  )
ggsave(filename = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/home_bias_population_scatter.png',
       width = 9,
       height = 6,
       dpi = 300)

