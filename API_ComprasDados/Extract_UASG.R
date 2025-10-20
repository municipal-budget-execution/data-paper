# install.packages(c("httr2","jsonlite","dplyr"))
library(httr2)
library(jsonlite)
library(dplyr)

get_uasg <- function(statusUasg = "true") {
  # statusUasg = "A" (Ativa) or "I" (Inativa)
  base_url <- "https://dadosabertos.compras.gov.br/modulo-uasg/1_consultarUasg"
  page <- 1
  all_data <- list()
  
  repeat {
    req <- request(base_url) |>
      req_url_query(
        pagina = page,
        tamanhoPagina = 500,
        statusUasg = statusUasg
      ) |>
      req_perform()
    
    res <- resp_body_json(req, simplifyVector = FALSE)
    dados <- res$resultado
    
    if (length(dados) == 0) break
    
    # Convert NULLs to NAs before binding
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

# ---- Example: get all ACTIVE UASGs ----
uasg_ativas <- get_uasg("true")

# (Optionally, to get inactive ones)
# uasg_inativas <- get_uasg("I")

# Preview
glimpse(uasg_ativas)
