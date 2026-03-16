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


set.seed(12345)

in_dir  <- "/Users/tscot/Dropbox/MiDES-data-paper-replication/Data"
figures = '/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures'

data_mides = fread(paste0(in_dir, '/Raw/mides_2021_items.csv')) 

data_mides = data_mides %>% 
  slice_sample(prop = .03) %>% 
  mutate(tender_objective = str_to_upper(descricao)) %>% 
  mutate(tender_objective = str_replace_all(tender_objective, "Ã", "A")) %>% 
  mutate(tender_objective = str_replace_all(tender_objective, "Ç", "C")) %>% 
  mutate(service = str_detect(tender_objective, 
                              "SERVIÇO|SERVICO|ALUGUEL|ALUGUÉL|ALUGUEL|MANUTENÇÃO|MANUTENCAO|CONSULTORIA|CONTRATAÇÃO|CONTRATACAO|ASSESSORIA|TREINAMENTO|CAPACITAÇÃO|CAPACITACAO|TRANSPORTE|FRETE|LOCAÇÃO|LOCACAO|LICENCIAMENTO|SUPORTE|INSTALAÇÃO|INSTALACAO|LIMPEZA|SEGURANÇA|SEGURANCA|VIGILÂNCIA|VIGILANCIA|MONITORAMENTO|DESENVOLVIMENTO|PROGRAMACAO|PROGR|SHOW|OBRA")) %>% 
  setDT()

text = data_mides[service == F]$tender_objective %>% paste(collapse = " ")
writeLines(text, con = paste0(in_dir,'/Intermediate/WordCloud/mides_goods/mides_goods.txt'))
text = data_mides[service == T]$tender_objective %>% paste(collapse = " ")
writeLines(text, con = paste0(in_dir,'/Intermediate/WordCloud/mides_services/mides_services.txt'))

####Goods Mides
corpus = Corpus(DirSource(paste0(in_dir,'/Intermediate/WordCloud/mides_goods')))
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
                        'secretaria', 'atend', 'futura', 'eventu', 'empresa', 'municipio', 'uso',
                        'data','validad', 'embalagem', 'pacot', 'materi'))
png(paste0(figures,'/WordCloud_mides_goods.png'))
wordcloud(corpus
          , max.words= 30   # Set top n words
          , random.order=FALSE # Words in decreasing freq
          , rot.per=0.25      # % of vertical words
          , use.r.layout=FALSE # Use C++ collision detection
          , colors=brewer.pal(8, "Dark2")
          , scale = c(2,1))
dev.off()


####Services
corpus = Corpus(DirSource(paste0(in_dir,'/Intermediate/WordCloud/mides_services')))
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


png(paste0(figures,'/WordCloud_mides_services.png'))
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
