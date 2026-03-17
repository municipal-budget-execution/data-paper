# code/analysis/tab_uasg_esferas.R
#
# Converted from code/archive/Table_Uasg_comprasdados.do
#
# Output:
#   output/tables/uasg_esferas.tex   — appendix table
#
# Data inputs (Data/Raw/comprasdados/):
#   uasg.csv
#   orgaos        (no extension, treated as CSV)
#   licitacoes_YEAR.csv          (YEAR = 2020..2024)
#   compras_sem_licitacao_YEAR.csv (YEAR = 2020..2024)

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

cd_dir <- file.path(input, "comprasdados")

# ---- Load reference tables ----

ug_list <- fread(file.path(cd_dir, "uasg.csv"), colClasses = "character")
# Normalise to lowercase so lookups are case-insensitive
setnames(ug_list, tolower(names(ug_list)))
# Fix BOM in first column name if present
setnames(ug_list, names(ug_list)[1], "ug_id")
setnames(ug_list, "codigoorgao", "ug_organ_id", skip_absent = TRUE)
# Keep minimal columns
ug_list <- ug_list[, .(ug_id, ug_organ_id, nomeuasg = get(
  intersect(c("nomeuasg", "NOMEUASG", "nome_uasg"), names(ug_list))[1]))]

# orgaos file (no extension)
orgao_path <- file.path(cd_dir, "orgaos")
if (!file.exists(orgao_path)) orgao_path <- file.path(cd_dir, "orgaos.csv")
orgao_list <- fread(orgao_path, colClasses = "character")
setnames(orgao_list, tolower(names(orgao_list)))
setnames(orgao_list, names(orgao_list)[1], "ug_organ_id")
orgao_list <- orgao_list[, .(ug_organ_id,
                              nomeorgao = get(intersect(c("nomeorgao","NOMEORGAO"),
                                                        names(orgao_list))[1]),
                              esfera    = get(intersect(c("esfera","ESFERA"),
                                                        names(orgao_list))[1]))]

# ---- Stack licitacoes + compras_sem_licitacao for years 2020-2024 ----

ANOS <- 2020:2024

stack_list <- lapply(ANOS, function(ano) {
  # Licitacoes
  lic_path <- file.path(cd_dir, paste0("licitacoes_", ano, ".csv"))
  lic <- if (file.exists(lic_path)) {
    dt <- fread(lic_path, colClasses = "character")
    # Normalise UASG column name
    uasg_col <- intersect(c("uasg", "UASG", "co_uasg"), names(dt))[1]
    if (is.na(uasg_col)) return(NULL)
    dt[, .(ug_id = get(uasg_col), ano = ano, com_licit = 1L)]
  } else NULL

  # Compras sem licitacao
  csl_path <- file.path(cd_dir, paste0("compras_sem_licitacao_", ano, ".csv"))
  csl <- if (file.exists(csl_path)) {
    dt <- fread(csl_path, colClasses = "character")
    uasg_col <- intersect(c("co_uasg", "uasg", "UASG"), names(dt))[1]
    if (is.na(uasg_col)) return(NULL)
    dt[duplicated(dt) == FALSE][, .(ug_id = get(uasg_col), ano = ano, sem_licit = 1L)]
  } else NULL

  rbindlist(Filter(Negate(is.null), list(lic, csl)), fill = TRUE)
})

compras_geral <- rbindlist(Filter(Negate(is.null), stack_list), fill = TRUE)

# ---- Merge with UG and Orgao ----

compras_geral <- merge(compras_geral, ug_list,    by = "ug_id",      all.x = TRUE)
compras_geral <- merge(compras_geral, orgao_list, by = "ug_organ_id", all.x = TRUE)
compras_geral[is.na(esfera) | esfera == "", esfera := "NA"]

# ---- Compute percentages by sphere and year ----

compras_geral[, esfera_cat := fcase(
  esfera == "F",  "Federal",
  esfera == "E",  "State",
  esfera == "M",  "Municipal",
  default         = "NA"
)]

pct_dt <- compras_geral[, .(N = .N), by = .(ano, esfera_cat)]
pct_dt[, total := sum(N), by = ano]
pct_dt[, pct   := round(100 * N / total, 2)]

# Reshape wide: rows = sphere category, cols = year
wide <- dcast(pct_dt, esfera_cat ~ ano, value.var = "pct", fill = 0)
setcolorder(wide, c("esfera_cat", as.character(ANOS)))

# Add Observations row
obs_row <- compras_geral[, .(N = .N), by = ano]
obs_wide <- dcast(obs_row, . ~ ano, value.var = "N")[, -"."]
obs_wide <- data.table(esfera_cat = "Observations", obs_wide)
setcolorder(obs_wide, c("esfera_cat", as.character(ANOS)))

# Ensure obs_wide columns match wide
for (col in setdiff(names(wide), names(obs_wide))) obs_wide[[col]] <- NA_real_

final_dt <- rbindlist(list(wide, obs_wide), fill = TRUE)

# ---- Write LaTeX table ----

yr_cols <- as.character(ANOS)
n_yr    <- length(yr_cols)

header <- paste0(
  "\\begin{tabular}{l", paste(rep("c", n_yr), collapse = ""), "}\n",
  "\\toprule\n",
  " & ", paste(yr_cols, collapse = " & "), " \\\\\n",
  "\\midrule"
)

body_rows <- apply(final_dt, 1, function(r) {
  vals <- r[yr_cols]
  # Format numbers: pct with 2 decimals, Observations with comma
  if (r["esfera_cat"] == "Observations") {
    vals_fmt <- formatC(as.numeric(vals), format = "d", big.mark = ",")
  } else {
    vals_fmt <- sprintf("%.2f", as.numeric(vals))
  }
  paste0(r["esfera_cat"], " & ", paste(vals_fmt, collapse = " & "), " \\\\")
})

tex_table <- paste(
  header,
  paste(body_rows, collapse = "\n"),
  "\\bottomrule\n\\end{tabular}",
  sep = "\n"
)

writeLines(tex_table, file.path(table_output, "uasg_esferas.tex"))
cat("  Wrote: output/tables/uasg_esferas.tex\n")
