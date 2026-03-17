# code/analysis/fig_wordclouds.R
# Outputs: Appendix word cloud figures
#   output/figures/WordCloud_goods_cropped.png    — MiDES goods
#   output/figures/WordCloud_services_cropped.png — MiDES services
#   output/figures/WordCloud_federal_goods_cropped.png    — federal goods
#   output/figures/WordCloud_federal_services_cropped.png — federal services
#
# Inputs:
#   Data/Raw/mides_2021_items.csv
#   Data/Intermediate/Transparency_Federal_2021/licitacoes_items_2021.rds
#   Data/Intermediate/WordCloud/ (intermediate text corpus files, auto-created)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("tm", "wordcloud", "SnowballC", "stopwords", "RColorBrewer",
               install = TRUE)

set.seed(12345)

# ---- Helper: detect service items ----

service_pattern <- paste0(
  "SERVIÇO|SERVICO|ALUGUEL|ALUGUÉL|MANUTENÇÃO|MANUTENCAO|CONSULTORIA|",
  "CONTRATAÇÃO|CONTRATACAO|ASSESSORIA|TREINAMENTO|CAPACITAÇÃO|CAPACITACAO|",
  "TRANSPORTE|FRETE|LOCAÇÃO|LOCACAO|LICENCIAMENTO|SUPORTE|INSTALAÇÃO|INSTALACAO|",
  "LIMPEZA|SEGURANÇA|SEGURANCA|VIGILÂNCIA|VIGILANCIA|MONITORAMENTO|",
  "DESENVOLVIMENTO|PROGRAMACAO|PROGR|SHOW|OBRA"
)

# Words to remove from corpus
remove_words_mun <- c(
  "100", "unidad", "500", "cor", "tipo", "tamanho", "nº", "ano", "litro",
  "serviço", "servico", "produto", "objeto", "pregao", "aquisicao", "aquisição",
  "eletronico", "prestacao", "necessidade", "contratacao", "contratação",
  "município", "preço", "registro", "eventual", "municip", "secretaria",
  "atend", "futura", "eventu", "empresa", "municipio", "uso", "data",
  "validad", "embalagem", "pacot", "materi"
)

# ---- Helper: build corpus, clean, generate wordcloud ----

make_wordcloud <- function(text_vec, remove_extra, out_path) {
  wc_dir <- tempfile()
  dir.create(wc_dir)
  writeLines(paste(text_vec, collapse = " "), file.path(wc_dir, "text.txt"))

  corpus <- Corpus(DirSource(wc_dir)) |>
    tm_map(stripWhitespace) |>
    tm_map(content_transformer(tolower)) |>
    tm_map(stemDocument) |>
    tm_map(removePunctuation) |>
    tm_map(removeWords, stopwords("pt")) |>
    tm_map(removeWords, remove_extra)

  png(out_path, width = 800, height = 600)
  wordcloud(corpus,
            max.words     = 30,
            random.order  = FALSE,
            rot.per       = 0.25,
            use.r.layout  = FALSE,
            colors        = brewer.pal(8, "Dark2"),
            scale         = c(2, 1))
  dev.off()
  unlink(wc_dir, recursive = TRUE)
}

# ============================================================
# Part 1: MiDES municipal word clouds
# ============================================================

mides_path <- file.path(bigquery, "mides_2021_items.csv")
if (!file.exists(mides_path)) {
  message("  --> fig_wordclouds.R [SKIPPED for MiDES — mides_2021_items.csv not found in Data/Raw/]")
} else {
  data_mides <- fread(mides_path)
  data_mides <- data_mides[sample(.N, ceiling(.N * 0.03))]  # 3% sample
  data_mides[, tender_objective := toupper(stringr::str_replace_all(descricao, "Ã", "A"))]
  data_mides[, tender_objective := stringr::str_replace_all(tender_objective, "Ç", "C")]
  data_mides[, service := grepl(service_pattern, tender_objective)]

  make_wordcloud(
    text_vec     = data_mides[service == FALSE]$tender_objective,
    remove_extra = remove_words_mun,
    out_path     = file.path(graph_output, "WordCloud_goods_cropped.png")
  )
  make_wordcloud(
    text_vec     = data_mides[service == TRUE]$tender_objective,
    remove_extra = remove_words_mun,
    out_path     = file.path(graph_output, "WordCloud_services_cropped.png")
  )
  cat("  Wrote: WordCloud_goods_cropped.png, WordCloud_services_cropped.png\n")
}

# ============================================================
# Part 2: Federal word clouds
# ============================================================

fed_path <- file.path(intermediate, "Transparency_Federal_2021", "licitacoes_items_2021.rds")
if (!file.exists(fed_path)) {
  message("  --> fig_wordclouds.R [SKIPPED for federal — licitacoes_items_2021.rds not found in Data/Intermediate/]")
} else {
  data_fed <- readRDS(fed_path)
  setDT(data_fed)
  data_fed <- data_fed[sample(.N, ceiling(.N * 0.10))]  # 10% sample
  data_fed[, descricao := stringr::str_replace_all(descricao, "ã", "a")]
  data_fed[, descricao := stringr::str_replace_all(descricao, "ç", "c")]
  data_fed[, tender_objective := toupper(descricao)]
  data_fed[, service := grepl(service_pattern, tender_objective)]

  make_wordcloud(
    text_vec     = data_fed[service == FALSE]$tender_objective,
    remove_extra = remove_words_mun,
    out_path     = file.path(graph_output, "WordCloud_federal_goods_cropped.png")
  )
  make_wordcloud(
    text_vec     = data_fed[service == TRUE]$tender_objective,
    remove_extra = remove_words_mun,
    out_path     = file.path(graph_output, "WordCloud_federal_services_cropped.png")
  )
  cat("  Wrote: WordCloud_federal_goods_cropped.png, WordCloud_federal_services_cropped.png\n")
}
