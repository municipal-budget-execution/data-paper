# ---------------------------------------------------------------------------- #
#                        Brazil Budget Execution Project                       #
#                              World Bank - DIME                               #
# ---------------------------------------------------------------------------- #

# Optional

#query <- "SELECT id_municipio, ano ,
    #AVG(CASE WHEN modalidade = '8' OR modalidade = '10' 
       #THEN 1 ELSE 0 END) AS share_discretion,
    #COUNT(id_licitacao_bd) AS count
    #FROM `basedosdados-dev.world_wb_mides.licitacao` 
    #GROUP BY id_municipio, ano"

#data <- read_sql(query)

#write.csv(data, paste0(input, "data_histogram_licitacao.csv"), row.names = FALSE)

input = '/Users/tscot/Downloads/RR_BRA_2023_19-v01 2/data-paper/Data/Raw'
graph_output = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures'


# Open file
file_path <- file.path(input, "data_histogram_licitacao.csv")
data <- read.csv(file_path)

# Histogram
data %>% filter(count > 50) %>% 
  ggplot() + 
  geom_histogram(aes(x = share_discretion), bins = 100,
                 color = "#0D3446",
                 fill = "#1A476F") + 
  xlab("Share of non-competitive tenders") +
  ylab("Number") +
  theme_classic() +
  theme(
    strip.text = element_text(size = 7, face = "bold"),
    axis.title = element_text(size = 11),
    axis.text=element_text(size=10)
  )
ggsave(filename = file.path(graph_output, "histogram_noncompetitive.png"),
       width = 8,
       height = 5)
 