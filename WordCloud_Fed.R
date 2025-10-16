# Install required packages
install.packages(c("tm", "wordcloud","SnowballC", "stopwords"))

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
library(haven)
library(janitor)

data_fed = fread("/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/202107_Licitacoes/202107_ItemLicitação.csv",
                 encoding = 'Latin-1')

data_fed = data_fed %>% clean_names()

data_fed = data_fed %>% 
  mutate(descricao = str_replace_all(descricao, "ã", "a")) %>% 
  mutate(descricao = str_replace_all(descricao, "ç", "c")) %>% 
  mutate(tender_objective = str_to_upper(descricao)) %>% 
  mutate(service = str_detect(tender_objective, 
                              "SERVIÇO|SERVICO|ALUGUEL|ALUGUÉL|ALUGUEL|MANUTENÇÃO|MANUTENCAO|CONSULTORIA|CONTRATAÇÃO|CONTRATACAO|ASSESSORIA|TREINAMENTO|CAPACITAÇÃO|CAPACITACAO|TRANSPORTE|FRETE|LOCAÇÃO|LOCACAO|LICENCIAMENTO|SUPORTE|INSTALAÇÃO|INSTALACAO|LIMPEZA|SEGURANÇA|SEGURANCA|VIGILÂNCIA|VIGILANCIA|MONITORAMENTO|DESENVOLVIMENTO|PROGRAMACAO|PROGR|SHOW|OBRA")) %>% 
  setDT()

# data_fed2021 = data_fed %>% mutate(ano = str_sub(year_month, 1, 4)) %>% 
#   filter(ano == 2021)
# rm(data_fed)

text = data_fed[service == F]$tender_objective %>% paste(collapse = " ")
writeLines(text, con = '/Users/tscot/Dropbox/WBER_RR/Data/WordCloud/federal_goods/federal_goods.txt')
text = data_fed[service == T]$tender_objective %>% paste(collapse = " ")
writeLines(text, con = '/Users/tscot/Dropbox/WBER_RR/Data/WordCloud/federal_services/federal_services.txt')

####Goods Federal
corpus = Corpus(DirSource("/Users/tscot/Dropbox/WBER_RR/Data/WordCloud/federal_goods"))
# Strip unnecessary whitespace
corpus = corpus %>% tm_map(stripWhitespace) %>% 
  tm_map(tolower) %>% 
  tm_map(stemDocument) %>% 
  tm_map(removePunctuation)%>% 
  tm_map(removeWords, stopwords("pt")) %>% 
  tm_map(removeWords, c('100', 'unidad', '500', 'cor', 'tipo', 'tamanho', 'tipo', 
                        'nº', 'ano', 'litro', 'serviço', 'servico', 'produto',
                        'objeto', 'pregao', 'aquisicao', 'aquisição', 'eletronico', 'prestacao', 'necessidade',
                        'contratacao', 'contratação', 'município', 'preço', 'registro', 'eventual', 'municip',
                        'secretaria', 'atend', 'futura', 'eventu', 'empresa', 'municipio', 'uso'))
png('/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/WordCloud_federal_goods.png')
wordcloud(corpus
          , max.words= 30   # Set top n words
          , random.order=FALSE # Words in decreasing freq
          , rot.per=0.25      # % of vertical words
          , use.r.layout=FALSE # Use C++ collision detection
          , colors=brewer.pal(8, "Dark2")
          , scale = c(2,1))
dev.off()


####Services
corpus = Corpus(DirSource("/Users/tscot/Dropbox/WBER_RR/Data/WordCloud/federal_services"))
# Strip unnecessary whitespace
corpus = corpus %>% tm_map(stripWhitespace) %>% 
  tm_map(tolower) %>% 
  tm_map(stemDocument) %>% 
  tm_map(removePunctuation)%>% 
  tm_map(removeWords, stopwords("pt")) %>% 
  tm_map(removeWords, c('100', 'unidad', '500', 'cor', 'tipo', 'tamanho', 'tipo', 
                        'nº', 'ano', 'litro', 'serviço', 'servico', 'produto',
                        'objeto', 'pregao', 'aquisicao', 'aquisição', 'eletronico', 'prestacao', 'necessidade',
                        'contratacao', 'contratação', 'município', 'preço', 'registro', 'eventual', 'municip',
                        'secretaria', 'atend', 'futura', 'eventu', 'empresa', 'municipio', 'uso'))


png('/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures/WordCloud_federal_services.png',
    width     = 552,
    height    = 366)
wordcloud(corpus
          , max.words= 30   # Set top n words
          , random.order=FALSE # Words in decreasing freq
          , rot.per=0.25      # % of vertical words
          , use.r.layout=FALSE # Use C++ collision detection
          , colors=brewer.pal(8, "Dark2")
          , scale = c(2,1))

dev.off()


data[, .(number = .N, share_purchase = sum(valor_total, na.rm = T)), 
     by = .(service)] %>% 
  mutate(share = share_purchase/sum(share_purchase))
