# code/analysis/fig_expenditure_composition.R
#
# Converted from code/archive/Figure_Elemento.do
#
# Output:
#   output/figures/composition_levels_expenditures.png  — appendix figure
#
# Data inputs (Data/Intermediate/ — monthly federal files + FINBRA):
#   2018XX_Despesas.csv  (XX = 01..12, one file per month)
#   finbra_state_elemento.csv
#   finbra_municipality_elemento.csv

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

# ---- Constants ----
# Expenditure element codes of interest
ELEM_CODES <- c(39L, 30L, 32L, 51L, 52L, 37L, 40L, 35L)

elem_labels <- c(
  `39` = "Other Services",
  `30` = "Supplies and materials",
  `51` = "Construction",
  `52` = "Equipment & Assets",
  `32` = "Goods for Free distribution",
  `35` = "Consulting Services",
  `37` = "Labor hiring",
  `40` = "IT and Communication Services"
)

# ---- Load and aggregate federal 2018 monthly expenditure ----
months <- sprintf("%02d", 1:12)
fed_list <- lapply(months, function(mm) {
  fpath <- file.path(intermediate, paste0("2018", mm, "_Despesas.csv"))
  if (!file.exists(fpath)) return(NULL)
  dt <- fread(fpath, encoding = "Latin-1")
  # Harmonise column names (Portuguese headers vary slightly)
  setnames(dt, tolower(gsub("[^a-zA-Z0-9_]", "_", names(dt))))
  # Keep relevant columns: function code, element code, paid value
  # Column names may differ; try common variants
  code_col  <- intersect(c("codigoelementodedespesa", "codigo_elemento_de_despesa",
                            "cod_elemento"), names(dt))[1]
  value_col <- grep("pago|valor_pago", names(dt), value = TRUE)[1]
  if (is.na(code_col) || is.na(value_col)) return(NULL)
  dt <- dt[, .(code_elemento = as.integer(get(code_col)),
               valor        = as.numeric(gsub(",", ".", get(value_col))))]
  dt
})
fed_raw <- rbindlist(Filter(Negate(is.null), fed_list), fill = TRUE)
fed_raw <- fed_raw[!is.na(valor)]

fed_agg <- fed_raw[code_elemento %in% ELEM_CODES,
                   .(valor = sum(valor, na.rm = TRUE)),
                   by = code_elemento]
fed_agg[, tot := sum(valor)]
fed_agg[, share := valor / tot * 100]
fed_agg[, sphere := "Federal"]

# ---- Load state FINBRA data ----
state_raw <- fread(file.path(intermediate, "finbra_state_elemento.csv"),
                   encoding = "Latin-1")
state_raw <- state_raw[grepl("Despesas Pagas", coluna, ignore.case = TRUE) |
                        grepl("Despesas Pagas", Coluna, ignore.case = TRUE)]
# Extract element code from "conta" column (characters 8-9 per original do file)
state_raw[, code_elemento := suppressWarnings(
  as.integer(substr(trimws(conta), 8L, 9L)))]
state_raw <- state_raw[code_elemento %in% ELEM_CODES]

# value columns start with "val" or similar
val_cols  <- grep("^val|^Val|^Valor", names(state_raw), value = TRUE)
# sum across all value columns after converting comma decimals
state_vals <- state_raw[, lapply(.SD, function(x)
  suppressWarnings(as.numeric(gsub(",", ".", x)))), .SDcols = val_cols]
state_raw[, valor := rowSums(state_vals, na.rm = TRUE)]

state_agg_mun <- state_raw[, .(valor = sum(valor, na.rm = TRUE)), by = code_elemento]
state_agg_mun[, tot := sum(valor)]
state_agg_mun[, share := valor / tot * 100]
state_agg_mun[, sphere := "State"]

# ---- Load municipality FINBRA data ----
munic_raw <- fread(file.path(intermediate, "finbra_municipality_elemento.csv"),
                   encoding = "Latin-1")
munic_raw <- munic_raw[grepl("Despesas Pagas", coluna, ignore.case = TRUE) |
                        grepl("Despesas Pagas", Coluna, ignore.case = TRUE)]
munic_raw[, code_elemento := suppressWarnings(
  as.integer(substr(trimws(conta), 8L, 9L)))]
munic_raw <- munic_raw[code_elemento %in% ELEM_CODES]

val_cols_m <- grep("^val|^Val|^Valor", names(munic_raw), value = TRUE)
munic_vals <- munic_raw[, lapply(.SD, function(x)
  suppressWarnings(as.numeric(gsub(",", ".", x)))), .SDcols = val_cols_m]
munic_raw[, valor := rowSums(munic_vals, na.rm = TRUE)]

munic_agg <- munic_raw[, .(valor = sum(valor, na.rm = TRUE)), by = code_elemento]
munic_agg[, tot := sum(valor)]
munic_agg[, share := valor / tot * 100]
munic_agg[, sphere := "Municipality"]

# ---- Stack and reshape ----
combined <- rbindlist(list(fed_agg[, .(sphere, code_elemento, share)],
                           state_agg_mun[, .(sphere, code_elemento, share)],
                           munic_agg[, .(sphere, code_elemento, share)]))

# Aggregate into 5 broad categories (matching original figure)
combined[, category := fcase(
  code_elemento %in% c(39L, 35L, 40L), "Services",
  code_elemento %in% c(30L, 32L),       "Goods and materials",
  code_elemento == 51L,                  "Construction",
  code_elemento == 52L,                  "Equipment & Assets",
  code_elemento == 37L,                  "Labor hiring"
)]
cat_agg <- combined[, .(share = sum(share, na.rm = TRUE)),
                    by = .(sphere, category)]

cat_order   <- c("Services", "Construction", "Labor hiring",
                 "Goods and materials", "Equipment & Assets")
cat_agg[, category := factor(category, levels = cat_order)]
cat_agg[, sphere   := factor(sphere,   levels = c("Federal", "State", "Municipality"))]

# ---- Plot ----
p_comp <- ggplot(cat_agg, aes(x = sphere, y = share, fill = category)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_y_continuous("Share of expenditure (%)", labels = scales::percent_format(scale = 1)) +
  scale_x_discrete(NULL) +
  scale_fill_manual(
    NULL,
    values = c(
      "Services"          = "#1A476F",
      "Construction"      = "#90353B",
      "Labor hiring"      = "#55752F",
      "Goods and materials" = "#E37E00",
      "Equipment & Assets"  = "#6E8E84"
    ),
    breaks = cat_order
  ) +
  theme_classic(base_size = 13) +
  theme(legend.position = "bottom",
        axis.text.x     = element_text(size = 12))

ggsave(file.path(graph_output, "composition_levels_expenditures.png"),
       p_comp, width = 9, height = 6, dpi = 300)

cat("  Wrote: composition_levels_expenditures.png\n")
