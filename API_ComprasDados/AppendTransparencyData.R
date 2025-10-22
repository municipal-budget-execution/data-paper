# Packages
library(data.table)
library(janitor)
library(dplyr)
library(data.table)

# ---- Settings ----
in_dir  <- "/Users/tscot/Dropbox/MiDES-data-paper-replication/Data/Raw/Transparency_Federal_2021"     # <- change to your folder
out_dir <- "/Users/tscot/Dropbox/MiDES-data-paper-replication/Data/Intermediate/Transparency_Federal_2021"

  # output file name (can include a full path)

######## LICITACAO #############
# ---- List the files (2021MM_*.csv for MM=01..12) ----
files <- list.files(
  path = in_dir,
  pattern = "^2021(0[1-9]|1[0-2])_Lic.*\\.csv$",
  full.names = TRUE
)

if (length(files) == 0L) stop("No matching CSV files found in: ", in_dir)

# (Optional) order by month based on the filename
ord <- as.integer(sub("^.*2021(\\d{2})_.*$", "\\1", basename(files)))
files <- files[order(ord)]

# ---- Read and append ----
DT_list <- lapply(files, function(f) {
  message("Reading: ", f)
  # fread auto-detects delimiter; encoding set to UTF-8 (adjust if needed)
  fread(f, encoding = "Latin-1", na.strings = c("", "NA", "NULL")) %>% 
    clean_names() %>% 
    .[, c('numero_licitacao', 'codigo_ug', 'codigo_modalidade_compra', 'uf', 'municipio', 'valor_licitacao')]
})

DT <- rbindlist(DT_list, use.names = TRUE, fill = TRUE)

# ---- Save as RDS ----
saveRDS(DT, file = file.path(out_dir, "licitacoes_2021.rds"))
fwrite(DT, file = file.path(out_dir, "licitacoes_2021.csv"))


######## ITEM #############

# ---- List the files (2021MM_*.csv for MM=01..12) ----
files <- list.files(
  path = in_dir,
  pattern = "^2021(0[1-9]|1[0-2])_ItemLici.*\\.csv$",
  full.names = TRUE
)

if (length(files) == 0L) stop("No matching CSV files found in: ", in_dir)

# ---- Read and append ----
DT_list <- lapply(files, function(f) {
  message("Reading: ", f)
  # fread auto-detects delimiter; encoding set to UTF-8 (adjust if needed)
  fread(f, encoding = "Latin-1", na.strings = c("", "NA", "NULL")) %>% 
    clean_names() %>% 
    .[, c('numero_licitacao', 'codigo_ug', 'codigo_modalidade_compra', 
          'descricao', 'quantidade_item',  'valor_item',
          'codigo_vencedor')]
})

DT <- rbindlist(DT_list, use.names = TRUE, fill = TRUE)

# ---- Save as RDS ----
saveRDS(DT, file = file.path(out_dir, "licitacoes_items_2021.rds"))
fwrite(DT, file = file.path(out_dir, "licitacoes_items_2021.csv"))
