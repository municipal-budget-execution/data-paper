# Packages
library(httr2)
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(tidyr)

BASE <- "https://pncp.gov.br/api/consulta"

# ---- 1) CONTRATAÇÕES por data de publicação ----
# Endpoint: /v1/contratacoes/publicacao
# Required: dataInicial, dataFinal (YYYYMMDD), codigoModalidadeContratacao, pagina
# Optional: codigoModoDisputa, uf, codigoMunicipioIbge, cnpj, codigoUnidadeAdministrativa, idUsuario, tamanhoPagina

get_contratacoes_publicacao <- function(data_inicial,
                                        data_final,
                                        codigo_modalidade,
                                        codigo_modo_disputa = NULL,
                                        uf = NULL,
                                        codigo_municipio_ibge = NULL,
                                        cnpj = NULL,
                                        codigo_unidade_adm = NULL,
                                        id_usuario = NULL,
                                        tamanho_pagina = 50) {
  
  fetch_page <- function(pagina) {
    req <- request(paste0(BASE, "/v1/contratacoes/publicacao")) |>
      req_url_query(
        dataInicial = data_inicial,
        dataFinal   = data_final,
        codigoModalidadeContratacao = codigo_modalidade,
        codigoModoDisputa = codigo_modo_disputa,
        uf = uf,
        codigoMunicipioIbge = codigo_municipio_ibge,
        cnpj = cnpj,
        codigoUnidadeAdministrativa = codigo_unidade_adm,
        idUsuario = id_usuario,
        pagina = pagina,
        tamanhoPagina = tamanho_pagina
      ) |>
      req_user_agent("pncp-r-client/0.1 (research)") |>
      req_error(is_error = ~ FALSE)
    
    resp <- req_perform(req)
    #stop_for_status(resp)
    json <- resp_body_json(resp, simplifyVector = FALSE)
    
    list(
      data = json$data %||% list(),
      total_paginas = json$totalPaginas %||% 0,
      numero_pagina = json$numeroPagina %||% pagina
    )
  }
  
  first <- fetch_page(1L)
  pages <- seq.int(first$numero_pagina + 1L, first$total_paginas)
  rest  <- if (length(pages)) map(pages, fetch_page) else list()
  
  all_data <- c(list(first), rest) |>
    map("data") |>
    flatten()
  
  # Safely tibblify (handles nested fields like amparoLegal, etc.)
  tibble(raw = all_data) |>
    mutate(row = row_number()) |>
    hoist(raw,
          numeroControlePNCP = "numeroControlePNCP",
          numeroCompra = "numeroCompra",
          anoCompra = "anoCompra",
          processo = "processo",
          modalidadeId = "modalidadeId",
          modalidadeNome = "modalidadeNome",
          modoDisputaId = "modoDisputaId",
          modoDisputaNome = "modoDisputaNome",
          situacaoCompraId = "situacaoCompraId",
          situacaoCompraNome = "situacaoCompraNome",
          objetoCompra = "objetoCompra",
          informacaoComplementar = "informacaoComplementar",
          srp = "srp") |>
    select(-raw)
}

# Example: consult Contratações published in 2023-08-01..2023-08-31, Pregão Eletrônico (modalidade 6)
# (See domain table for codes; Pregão-Eletrônico=6)
contratacoes_df <- get_contratacoes_publicacao(
  data_inicial = "20230801",
  data_final   = "20230831",
  codigo_modalidade = 6,      # Pregão Eletrônico
  tamanho_pagina = 50
)

# ---- 2) CONTRATOS por data de publicação ----
# Endpoint: /v1/contratos
# Required: dataInicial, dataFinal, pagina
# Optional: cnpjOrgao, codigoUnidadeAdministrativa, usuarioId, tamanhoPagina (max 500)

get_contratos_publicacao <- function(data_inicial,
                                     data_final,
                                     cnpj_orgao = NULL,
                                     codigo_unidade_adm = NULL,
                                     usuario_id = NULL,
                                     tamanho_pagina = 500) {
  
  fetch_page <- function(pagina) {
    req <- request(paste0(BASE, "/v1/contratos")) |>
      req_url_query(
        dataInicial = data_inicial,
        dataFinal   = data_final,
        cnpjOrgao   = cnpj_orgao,
        codigoUnidadeAdministrativa = codigo_unidade_adm,
        usuarioId   = usuario_id,
        pagina = pagina,
        tamanhoPagina = tamanho_pagina
      ) |>
      req_user_agent("pncp-r-client/0.1 (research)") |>
      req_error(is_error = ~ FALSE)
    
    resp <- req_perform(req)
    stop_for_status(resp)
    json <- resp_body_json(resp, simplifyVector = FALSE)
    
    list(
      data = json$data %||% list(),
      total_paginas = json$totalPaginas %||% 0,
      numero_pagina = json$numeroPagina %||% pagina
    )
  }
  
  first <- fetch_page(1L)
  pages <- seq.int(first$numero_pagina + 1L, first$total_paginas)
  rest  <- if (length(pages)) map(pages, fetch_page) else list()
  
  all_data <- c(list(first), rest) |>
    map("data") |>
    flatten()
  
  tibble(raw = all_data) |>
    mutate(row = row_number()) |>
    hoist(raw,
          numeroControlePNCP = "numeroControlePNCP",                  # id contrato PNCP
          numeroControlePNCPCompra = "numeroControlePNCPCompra",      # link to contratação PNCP
          numeroContratoEmpenho = "numeroContratoEmpenho",
          anoContrato = "anoContrato",
          processo = "processo",
          valorGlobal = "valorGlobal",
          valorAcumulado = "valorAcumulado",
          dataAssinatura = "dataAssinatura",
          dataPublicacaoPncp = "dataPublicacaoPncp",
          dataAtualizacao = "dataAtualizacao") |>
    select(-raw)
}

# Example: all contracts published in same 2023-08 month
contratos_df <- get_contratos_publicacao(
  data_inicial = "20230801",
  data_final   = "20230831",
  tamanho_pagina = 500
)

# ---- 3) JOIN: contratos ↔ contratações ----
# numeroControlePNCPCompra in the contracts links back to numeroControlePNCP from contratações.
contratos_joined <- contratos_df %>%
  left_join(contratacoes_df,
            by = c("numeroControlePNCPCompra" = "numeroControlePNCP"),
            suffix = c("_contrato", "_compra"))
