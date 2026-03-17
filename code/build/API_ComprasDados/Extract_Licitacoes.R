# Packages
# install.packages(c("httr2","jsonlite","dplyr","purrr","lubridate"))
library(httr2)
library(jsonlite)
library(dplyr)
library(purrr)
library(lubridate)
library(tibble)

# Replace every inner NULL with NA (recursively for nested lists)
null_to_na <- function(x) {
  if (is.list(x)) {
    map(x, null_to_na)
  } else if (is.null(x)) {
    NA
  } else {
    x
  }
}

# Turn a page's `resultado` list into a tibble safely
resultado_to_tibble <- function(resultados) {
  if (length(resultados) == 0) return(tibble())
  resultados %>%
    map(~ null_to_na(.x)) %>%          # make sure no element is NULL
    map(~ as_tibble(.x)) %>%           # now safe
    bind_rows()                        # union of columns across records
}

# ---- Core fetcher for one day-window (<= 365 days) ----
fetch_licitacoes_window <- function(date_start, date_end,
                                    tamanho_pagina = 500,
                                    extra_params = list(), # e.g. list(uasg=160123, modalidade=5)
                                    verbose = TRUE, pause = 0.2, max_pages = Inf) {
  base_url <- "https://dadosabertos.compras.gov.br/modulo-legado/1_consultarLicitacao"
  page <- 1
  out <- list()
  
  repeat {
    q <- c(
      list(
        pagina = page,
        tamanhoPagina = tamanho_pagina,
        data_publicacao_inicial = format(as.Date(date_start), "%Y-%m-%d"),
        data_publicacao_final   = format(as.Date(date_end),   "%Y-%m-%d")
      ),
      extra_params
    )
    
    req <- request(base_url) |> req_url_query(!!!q)
    resp <- req |> req_perform()
    
    if (resp_status(resp) >= 400) {
      stop(sprintf("HTTP %s on page %s for %s..%s",
                   resp_status(resp), page, date_start, date_end))
    }
    
    parsed <- resp_body_json(resp, simplifyVector = FALSE)
    # Defensive parsing
    resultados <- parsed$resultado %||% list()
    total_paginas <- parsed$totalPaginas %||% 0
    paginas_rest <- parsed$paginasRestantes %||% 0
    
    if (length(resultados) > 0) out[[length(out) + 1]] <- resultados
    if (verbose) message(sprintf(
      "[%s..%s] page %d / totalPaginas=%s, restantes=%s, got=%d",
      date_start, date_end, page, as.character(total_paginas),
      as.character(paginas_rest), length(resultados)
    ))
    
    # Stop conditions
    if (page >= total_paginas || paginas_rest == 0 || page >= max_pages) break
    
    page <- page + 1
    if (pause > 0) Sys.sleep(pause)  # be nice to the API
  }
  
  # Bind rows into a tibble
  if (length(out) == 0) return(tibble())
  df <- out %>%
    list_flatten() %>%                   # flatten pages into a single record list
    resultado_to_tibble()
  df
}

# ---- Helper: split a long range into <=365-day chunks ----
split_into_windows <- function(start_date, end_date, window_days = 365) {
  start_date <- as.Date(start_date)
  end_date   <- as.Date(end_date)
  if (end_date < start_date) stop("end_date < start_date")
  
  # Build sequence of window starts
  starts <- seq(from = start_date, to = end_date, by = paste0(window_days, " days"))
  ends   <- pmin(starts + days(window_days - 1), end_date)
  tibble(date_start = starts, date_end = ends)
}

# ---- Public function: fetch all licitações across any range ----
get_licitacoes <- function(start_date, end_date,
                           tamanho_pagina = 500,
                           extra_params = list(),
                           verbose = TRUE, pause = 0.2) {
  windows <- split_into_windows(start_date, end_date, window_days = 365)
  
  res <- pmap_dfr(
    list(windows$date_start, windows$date_end),
    ~ fetch_licitacoes_window(..1, ..2,
                              tamanho_pagina = tamanho_pagina,
                              extra_params = extra_params,
                              verbose = verbose, pause = pause)
  )
  
  # Optional: parse date fields to Date/POSIXct where present
  date_cols <- intersect(c("data_abertura_proposta","data_entrega_edital","data_entrega_proposta","data_publicacao"),
                         names(res))
  for (cc in date_cols) res[[cc]] <- as.Date(res[[cc]], format = "%Y-%m-%d")
  if ("dt_alteracao" %in% names(res)) {
    # dt_alteracao is ISO-8601 with time
    res$dt_alteracao <- suppressWarnings(as.POSIXct(res$dt_alteracao, tz = "UTC"))
  }
  
  res
}

# ------------------------
# EXAMPLES
# ------------------------

# 1) All licitações in calendar year 2024 (auto-splits into 365-day windows if needed)
#    NOTE: You can narrow with extra_params = list(uasg=..., modalidade=..., numero_aviso=...)
licit_2024 <- get_licitacoes("2021-01-01", "2021-12-31")
fwrite(licit_2024, file = '/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/ComprasDdos/licitacoes_2021.csv')
# 2) Narrowed example: a specific UASG and modality within 2025 YTD
# licit_uasg <- get_licitacoes("2025-01-01", Sys.Date(),
#                              extra_params = list(uasg = 160123, modalidade = 5))

# Peek
dplyr::glimpse(licit_2024)
