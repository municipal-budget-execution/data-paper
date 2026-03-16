# code/analysis/fig_rdd_mayors.R
#
# Converted from code/archive/RDD_mayors.do
#
# Outputs:
#   output/figures/Dahis Fig 12a.pdf  — main paper Fig 12a: RDD plot, % non-competitive
#   output/figures/Dahis Fig 12b.pdf  — main paper Fig 12b: RDD plot, % local procurement
#   output/tables/RDD_mayors.tex      — main paper Tab 6
#
# Data inputs:
#   Data/Raw/licitacao.csv            — tender-level data
#   Data/Raw/participante_cnpj.csv    — participant data (winners)
#   Data/Intermediate/mayors.dta      — election results + mayor demographics

source(here::here("code/utils/paths.R"))
source(here::here("code/utils/packages.R"))

pacman::p_load("fixest", "haven", "rdrobust", install = TRUE, character.only = TRUE)

# ---- Load and prepare tender data ----

lic <- fread(file.path(input, "licitacao.csv"))
lic[, discret_tender := as.integer(modalidade %in% c(8L, 10L))]
lic <- lic[ano != 2021]  # no mayor data for 2021
lic[, term := fcase(
  ano %between% c(2009L, 2012L), 2009L,
  ano %between% c(2013L, 2016L), 2013L,
  ano %between% c(2017L, 2020L), 2017L
)]
non_comp <- lic[!is.na(term), .(discret_tender = mean(discret_tender, na.rm = TRUE)),
                by = .(municipality_id = id_municipio, term)]

# ---- Load and prepare participant data ----

part <- fread(file.path(input, "participante_cnpj.csv"))
part[, same_municipality := as.integer(!is.na(id_municipio_1) & id_municipio_1 == id_municipio)]
part <- part[vencedor == 1 & ano != 2021]
part[, term := fcase(
  ano %between% c(2009L, 2012L), 2009L,
  ano %between% c(2013L, 2016L), 2013L,
  ano %between% c(2017L, 2020L), 2017L
)]
local_tenders <- part[!is.na(term), .(same_municipality = mean(same_municipality, na.rm = TRUE)),
                      by = .(municipality_id = id_municipio, term)]

# ---- Load mayor data ----

mayors <- haven::read_dta(file.path(intermediate, "mayors.dta")) |> setDT()
mayors <- mayors[year >= 2008]

mayors[, first := fcase(term_number == 1, 1L, term_number == 2, 0L)]

# Party dummies
main_parties <- c("PDT", "PFL", "PL", "PMDB", "PP", "PPS", "PSB", "PSDB", "PT", "PTB")
for (p in main_parties) {
  mayors[, paste0("party_", p) := as.integer(party == p)]
}
mayors[, party_other := as.integer(!party %in% main_parties)]

# Gender and schooling dummies
mayors[, male   := as.integer(gender == "masculino")]
mayors[, female := as.integer(gender == "feminino")]

school_levels <- c("le e escreve", "ensino fundamental incompleto",
                   "ensino fundamental completo", "ensino medio incompleto",
                   "ensino medio completo", "ensino superior incompleto",
                   "ensino superior completo")
for (i in seq_along(school_levels)) {
  mayors[, paste0("schooling_", i) := as.integer(education == school_levels[i])]
}
mayors[, schooling_missing := as.integer(education == "NA" | is.na(education))]

# Age
mayors[, age := suppressWarnings(as.numeric(as.character(age)))]
mayors[, age_missing := as.integer(is.na(age))]
mayors[is.na(age), age := 0]
mayors[, age2 := age^2]
mayors[, age3 := age^3]

# Running variable: margin of victory for first-term mayor
mayors[, wm      := fifelse(first == 0L, win_margin / 100, NA_real_)]
mayors[inclost == 1L, wm := winmargin_inclost / 100]
mayors[, running := -wm]
mayors[inclost == 1L, running := wm]

# Merge
dt_all <- merge(non_comp, local_tenders, by = c("municipality_id", "term"), all = TRUE)
dt_all <- merge(dt_all, mayors,
                by.x = c("municipality_id", "term"),
                by.y = c("municipality_id", "term"),
                all.x = TRUE)
dt_all <- dt_all[!is.na(running)]

# ---- Covariate matrix for rdrobust ----

cov_cols <- c(
  grep("^schooling_", names(dt_all), value = TRUE),
  "male", "age", "age2", "age3",
  grep("^party_", names(dt_all), value = TRUE)
)
# Add state dummies
dt_all[, uf_fac := as.integer(factor(sigla_uf))]

build_covs <- function(dt) {
  cov_mat <- as.matrix(dt[, c(cov_cols, "uf_fac"), with = FALSE])
  # drop columns with zero variance
  cov_mat[, apply(cov_mat, 2, var, na.rm = TRUE) > 0, drop = FALSE]
}

# ---- RDD regressions ----

outcomes  <- c("discret_tender", "same_municipality")
bw_labels <- list(CCT = 1, ".5CCT" = 0.5, "2CCT" = 2)

results <- list()

for (outcome in outcomes) {
  dt_out <- dt_all[!is.na(get(outcome)) & !is.na(running)]
  covs   <- build_covs(dt_out)

  # CCT bandwidth
  bw_obj <- rdbwselect(dt_out[[outcome]], dt_out$running,
                       covs = covs, p = 1, bwselect = "mserd")
  h_cct  <- bw_obj$bws[1, "h"]

  for (bw_name in names(bw_labels)) {
    h <- h_cct * bw_labels[[bw_name]]
    rdd <- rdrobust(dt_out[[outcome]], dt_out$running,
                    covs = covs, p = 1, h = c(h, h))
    results[[paste(outcome, bw_name, sep = "_")]] <- list(
      coef   = rdd$coef[1],     # conventional estimate
      se     = rdd$se[3],       # robust SE
      ci_lb  = rdd$ci[3, 1],   # robust 90% CI lower
      ci_ub  = rdd$ci[3, 2],   # robust 90% CI upper
      N      = rdd$N[1] + rdd$N[2],
      h      = h,
      kernel = "Triangular",
      bw_sel = bw_name
    )
  }

  # RDD plot for main figure (using CCT bandwidth)
  dt_plot <- dt_out[abs(running) <= h_cct * 2]
  bw_h    <- h_cct

  rdp <- rdplot(dt_out[[outcome]], dt_out$running, h = bw_h * 2,
                title = "", x.label = "Margin of victory",
                y.label = if (outcome == "discret_tender") "% Non-competitive tenders"
                          else "% Tenders with local supplier",
                col.dots = "gray60", col.lines = "#1A476F", ci = 90)

  fig_file <- if (outcome == "discret_tender") "Dahis Fig 12a.pdf"
              else                             "Dahis Fig 12b.pdf"

  ggsave(file.path(graph_output, fig_file),
         rdp$rdplot, width = 6, height = 5, device = cairo_pdf)
}

# ---- Format LaTeX table (matching esttab style of original) ----

star <- function(coef, se) {
  p <- 2 * pnorm(-abs(coef / se))
  symb <- if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.10) "*" else ""
  sprintf("%.3f%s", coef, symb)
}

fmt_se  <- function(se)   sprintf("(%.3f)", se)
fmt_ci  <- function(lb, ub) sprintf("[%.3f ; %.3f]", lb, ub)
fmt_bw  <- function(h)    sprintf("%.3f", h)
fmt_n   <- function(n)    formatC(n, format = "d", big.mark = ",")

bw_order <- c("CCT", ".5CCT", "2CCT")

# Build one column per (outcome × bandwidth)
get_r <- function(out, bw) results[[paste(out, bw, sep = "_")]]

rows <- list(
  coef_row    = c("First-term mayor",
                  sapply(outcomes, function(o) sapply(bw_order, function(b)
                    star(get_r(o,b)$coef, get_r(o,b)$se)))),
  se_row      = c("",
                  sapply(outcomes, function(o) sapply(bw_order, function(b)
                    fmt_se(get_r(o,b)$se)))),
  ci_row      = c("Robust 90\\% CI",
                  sapply(outcomes, function(o) sapply(bw_order, function(b)
                    fmt_ci(get_r(o,b)$ci_lb, get_r(o,b)$ci_ub)))),
  kernel_row  = c("Kernel Type", rep("Triangular", 6)),
  bwtype_row  = c("BW Type",
                  sapply(outcomes, function(o) bw_order)),
  bw_row      = c("BW",
                  sapply(outcomes, function(o) sapply(bw_order, function(b)
                    fmt_bw(get_r(o,b)$h)))),
  n_row       = c("Observations",
                  sapply(outcomes, function(o) sapply(bw_order, function(b)
                    fmt_n(get_r(o,b)$N))))
)

make_tex_row <- function(cells, midrule_before = FALSE) {
  prefix <- if (midrule_before) "\\midrule\n" else ""
  paste0(prefix,
         paste(cells, collapse = " & "),
         " \\\\")
}

header <- paste0(
  "\\begin{tabular}{l*{6}{c}}\n",
  "\\toprule\n",
  " & \\multicolumn{3}{c}{\\% Non-competitive tenders}",
  " & \\multicolumn{3}{c}{\\% Tenders with local supplier}",
  " \\\\ \\cmidrule(lr){2-4}  \\cmidrule(lr){5-7}\n",
  " & \\multicolumn{1}{c}{(1)} & \\multicolumn{1}{c}{(2)} & \\multicolumn{1}{c}{(3)}",
  " & \\multicolumn{1}{c}{(4)} & \\multicolumn{1}{c}{(5)} & \\multicolumn{1}{c}{(6)} \\\\\n",
  "\\midrule"
)

body <- paste(
  make_tex_row(rows$coef_row),
  make_tex_row(rows$se_row),
  make_tex_row(rows$ci_row,  midrule_before = TRUE),
  make_tex_row(rows$kernel_row),
  make_tex_row(rows$bwtype_row),
  make_tex_row(rows$bw_row),
  make_tex_row(rows$n_row),
  sep = "\n"
)

tex_table <- paste(
  header, body,
  "\\bottomrule\n\\end{tabular}",
  sep = "\n"
)

writeLines(tex_table, file.path(table_output, "RDD_mayors.tex"))
cat("  Wrote: Dahis Fig 12a.pdf, Dahis Fig 12b.pdf, output/tables/RDD_mayors.tex\n")
