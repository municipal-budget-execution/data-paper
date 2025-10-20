# install.packages(c("httr2","jsonlite","dplyr"))
library(httr2)
library(jsonlite)
library(dplyr)

# ---- Simple function ----
get_compras_sem_licitacao <- function(year) {
  base_url <- "https://dadosabertos.compras.gov.br/modulo-legado/5_consultarComprasSemLicitacao"
  page <- 1
  all_data <- list()
  
  repeat {
    req <- request(base_url) |>
      req_url_query(
        pagina = page,
        tamanhoPagina = 500,
        dt_ano_aviso = year
      ) |>
      req_perform()
    
    res <- resp_body_json(req, simplifyVector = FALSE)
    dados <- res$resultado
    
    if (length(dados) == 0) break
    
    # Convert NULLs to NA and make tibble
    df <- lapply(dados, \(x) {
      x[sapply(x, is.null)] <- NA
      as.data.frame(x)
    }) |> bind_rows()
    
    all_data[[page]] <- df
    
    if (res$paginasRestantes == 0) break
    page <- page + 1
  }
  
  bind_rows(all_data)
}

# ---- Example: pull data for 2024 ----
compras_2021 <- get_compras_sem_licitacao(2021)
fwrite(compras_2021, file = '/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/ComprasDdos/compras_nolic_2021.csv')
# Quick preview
glimpse(compras_2024)
