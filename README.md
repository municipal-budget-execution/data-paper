# MiDES: New Data and Facts from Local Procurement and Budget Execution in Brazil

Replication package for the paper published in the **World Bank Economic Review**.

---

## Overview

This package contains all the code needed to reproduce every table and figure in the paper, starting from the processed input data files.

**One command reproduces everything:**

```bash
bash main.sh
```

Outputs are written to `output/figures/` and `output/tables/`.

---

## Requirements

**Software:** R ≥ 4.3. No Python required.

**R packages** are declared in `code/utils/packages.R` and installed automatically on first run via `pacman`. Key packages:

| Purpose | Packages |
|---|---|
| Data manipulation | `data.table`, `dplyr` |
| Figures | `ggplot2`, `ggpubr`, `ggtext`, `ggrepel` |
| Maps | `sf`, `geobr` |
| Econometrics | `fixest`, `binsreg`, `rdrobust` |
| Tables | `kableExtra`, `modelsummary`, `tinytex` |
| Data I/O | `readxl`, `haven`, `janitor` |

LaTeX (e.g. TinyTeX via `tinytex::install_tinytex()`) is required to compile the regression table PDFs.

**Input data** lives outside the repository, in a Dropbox folder (`MiDES-data-paper-replication/Data/Raw/`). The paths are configured per-user in `code/utils/paths.R`.

---

## Running the package

```bash
# Reproduce all outputs using existing processed data
bash main.sh

# Re-fetch raw data from BigQuery first, then reproduce
bash main.sh --redownload
```

The `--redownload` flag requires a Google Cloud project configured with `basedosdados` credentials. Most replicators will not need it — the processed input CSVs are provided with the package.

**Approximate runtime:** ~10 minutes on a standard 2024 laptop.

---

## Repository structure

```
MiDES-data-paper-repository/
├── main.sh                    ← single entry point
├── CLAUDE.md                  ← AI coding conventions
├── code/
│   ├── analysis/              ← one R script per figure/table group
│   ├── build/                 ← data ingestion from BigQuery/APIs
│   │   ├── ingest_bigquery.R
│   │   ├── API_ComprasDados/
│   │   └── queries/
│   ├── utils/                 ← shared helpers (paths, packages, theme, pdf_table)
│   └── archive/               ← original scripts and notebooks, kept for reference
└── docs/
    └── documentation_in_portuguese.pdf
```

---

## Figure and table → script mapping

### Main paper figures

| Figure | Output filename | Script |
|---|---|---|
| Fig 1 | `Dahis Fig 1.png` | *manually created* |
| Fig 2 | `Dahis Fig 2.pdf` | *manually created* |
| Fig 3 | `Dahis Fig 3.pdf` | `code/analysis/fig_validation_siconfi.R` |
| Fig 4 | `Dahis Fig 4.pdf` | `code/analysis/fig_validation_siconfi.R` |
| Fig 5 | `Dahis Fig 5.pdf` | `code/analysis/fig_validation_siconfi.R` |
| Fig 6a, 6b | `Dahis Fig 6a.png`, `Dahis Fig 6b.png` | `code/analysis/fig_waiver_thresholds.R` |
| Fig 7 | `Dahis Fig 7.png` | `code/analysis/fig_home_bias.R` |
| Fig 8 | `Dahis Fig 8.png` | `code/analysis/fig_home_bias_federal.R` |
| Fig 9a, 9b | `Dahis Fig 9a.png`, `Dahis Fig 9b.png` | `code/analysis/fig_delay_payment.R` |
| Fig 10 | `Dahis Fig 10.png` | `code/analysis/fig_delay_maps.R` |
| Fig 11 | `Dahis Fig 11.png` | `code/analysis/fig_scatter_delay_gdp.R` |
| Fig 12a, 12b | `Dahis Fig 12a.pdf`, `Dahis Fig 12b.pdf` | `code/analysis/fig_rdd_mayors.R` ¹ |

### Appendix figures

| Figure | Output filename | Script |
|---|---|---|
| Fig A1 | `validation_siconfi_commitment_function.pdf` | `code/analysis/fig_validation_siconfi.R` |
| Fig A2 | `validation_siconfi_verification_function.pdf` | `code/analysis/fig_validation_siconfi.R` |
| Fig A3 | `validation_siconfi_payment_function.pdf` | `code/analysis/fig_validation_siconfi.R` |
| Fig A4 | `validation_siconfi_payment_pr.pdf`, `_mg.pdf` | `code/analysis/fig_validation_siconfi.R` |
| Fig A5 | `over30_delay_2018.png` | `code/analysis/fig_delay_maps.R` |
| Fig A6 | `cdf_years_over_30days.jpeg` | `code/analysis/fig_delay_payment.R` |
| Fig A7 | `histogram_noncompetitive.png` | `code/analysis/fig_noncompetitive_hist.R` |
| Appendix: home bias by type (unweighted) | `home_bias_by_type_unw.png` | `code/analysis/fig_home_bias.R` |
| Appendix: home bias by population (unweighted) | `home_bias_population_unw.png` | `code/analysis/fig_home_bias.R` |
| Appendix: home bias scatter vs. population | `home_bias_population_scatter.png` | `code/analysis/fig_home_bias.R` |
| Appendix: home bias by state (weighted) | `home_bias_by_state_weighted.png` | `code/analysis/fig_home_bias_federal.R` |
| Appendix: home bias by type (weighted) | `home_bias_by_type_weighted.png` | `code/analysis/fig_home_bias_federal.R` |
| Appendix: home bias by population (weighted) | `home_bias_population_weighted.png` | `code/analysis/fig_home_bias_federal.R` |
| Appendix: home bias scatter both | `home_bias_population_scatter_both.png` | `code/analysis/fig_home_bias_federal.R` |
| Appendix: federal vs. municipal scatter (weighted) | `scatter_federal_localpurchase_weighted.png` | `code/analysis/fig_home_bias_federal.R` |
| Appendix: waiver distribution (federal tenders) | `distribution_tender_federal.png` | `code/analysis/fig_waiver_thresholds.R` |
| Appendix: waiver distribution (federal items) | `distribution_items_federal.png` | `code/analysis/fig_waiver_thresholds.R` |
| Appendix: expenditure composition | `composition_levels_expenditures.png` | `code/analysis/fig_expenditure_composition.R` ¹ |
| Fig B1–B4 | `proporcao_nulos_*.pdf` | `code/analysis/fig_null_ids.R` |
| Fig B5 | `missing_municipalities_procurement.pdf` | `code/analysis/fig_missing_municipalities.R` |
| Fig B6 | `missing_municipalities_budget_sample.pdf` | `code/analysis/fig_missing_municipalities.R` |
| Fig B7 | `total_municipalities_commitment.pdf` | `code/analysis/fig_total_municipalities.R` |
| Fig B8 | `total_municipalities_verification.pdf` | `code/analysis/fig_total_municipalities.R` |
| Fig B9 | `total_municipalities_payment.pdf` | `code/analysis/fig_total_municipalities.R` |

### Main paper tables

| Table | Output filename | Script |
|---|---|---|
| Tab 1 | `coverage_table.tex` | *manually created* |
| Tab 2 | `descriptive_statistics_municipalities.tex` | `code/analysis/tab_descriptive_municipalities.R` |
| Tab 3 | `descriptive_statistics_procurement.tex` | `code/analysis/tab_descriptive_procurement.R` |
| Tab 4 | `descriptive_statistics_budget_execution.tex` | `code/analysis/tab_descriptive_execution.R` |
| Tab 5 | `reg_home_bias_correlates.tex` → `output/figures/` | `code/analysis/tab_regressions_home_bias.R` |
| Tab 6 | `regression_home_bias.tex` → `output/figures/` | `code/analysis/fig_home_bias_federal.R` |
| Tab 7 | `table_reg_4_columns.tex` | `code/analysis/tab_regressions_delay.R` |
| Tab 8 | `RDD_mayors.tex` | `code/analysis/fig_rdd_mayors.R` ¹ |

### Appendix tables

| Table | Output filename | Script |
|---|---|---|
| Appendix: UASG esferas | `uasg_esferas.tex` | `code/analysis/tab_uasg_esferas.R` |
| Appendix: municipalities by state | `descriptive_statistics_municipalities_by_state.tex` | `code/analysis/tab_descriptive_municipalities.R` |
| Appendix: home bias correlates (weighted) | `reg_home_bias_correlates_weighted.tex` → `output/figures/` | `code/analysis/fig_home_bias_federal.R` |
| Appendix: home bias regression (weighted) | `regression_home_bias_weighted.tex` → `output/figures/` | `code/analysis/fig_home_bias_federal.R` |
| Appendix: SICONFI deviations | `reg_deviations.tex` | `code/analysis/tab_regressions_delay.R` |
| Appendix: data sources | `data_sources.tex` | *manually created* |
| Appendix: budget execution limitations | `limitations_budget_execution.tex` | *manually created* |
| Appendix: procurement limitations | `limitations_procurement.tex` | *manually created* |

> **Note:** Some regression tables (`reg_home_bias_correlates.tex`, `regression_home_bias.tex`, `reg_home_bias_correlates_weighted.tex`, `regression_home_bias_weighted.tex`) are written to `output/figures/` rather than `output/tables/` because the paper's master `.tex` file reads them via `\input{figures/...}`.

¹ Scripts marked with ¹ require intermediate data files not re-created by `--redownload`. See **Intermediate data** below.

---

## Data

### Raw input data

The processed input CSVs are stored in Dropbox at `MiDES-data-paper-replication/Data/Raw/` and are **not committed to this repository**.

Raw data is collected from 7 Brazilian State Audit Courts (TCEs):

| State | Source |
|---|---|
| CE | https://api-dados-abertos.tce.ce.gov.br/docs/ |
| MG | https://dadosabertos.tce.mg.gov.br |
| PB | https://dados.tce.pb.gov.br |
| PE | https://sistemas.tce.pe.gov.br/DadosAbertos |
| PR | https://servicos.tce.pr.gov.br/TCEPR/Tribunal/Relacon/Dados/DadosConsulta/Consolidado |
| RS | http://dados.tce.rs.gov.br |
| SP | https://transparencia.tce.sp.gov.br/conjunto-de-dados |

Harmonized versions of these tables are hosted on [Base dos Dados](https://basedosdados.org) in Google BigQuery (`basedosdados.world_wb_mides.*`). The `--redownload` flag in `main.sh` re-fetches them via `code/build/ingest_bigquery.R`.

### Intermediate data

Several scripts require pre-built files in `Data/Intermediate/` that are not in `Data/Raw/` and not rebuilt by `--redownload`. These must be present on the machine:

| File | Required by |
|---|---|
| `Transparency_Federal_2021/licitacoes_2021.csv` | `fig_waiver_thresholds.R` |
| `Transparency_Federal_2021/licitacoes_items_2021.csv` | `fig_waiver_thresholds.R` |
| `Transparency_Federal_2021/licitacoes_2021.rds` | `fig_home_bias_federal.R` |
| `Transparency_Federal_2021/licitacoes_items_2021.rds` | `fig_home_bias_federal.R` |
| `Transparency_Federal_2021/suppliers_munic_federal.csv` | `fig_home_bias_federal.R` |
| `Transparency_Federal_2021/mides_2021_items_alternative_price.csv` | `fig_home_bias_federal.R` |
| `mayors.dta` | `fig_rdd_mayors.R` (Fig 12, Tab 8) |
| `2018XX_Despesas.csv` (12 monthly files) | `fig_expenditure_composition.R` |
| `finbra_state_elemento.csv` | `fig_expenditure_composition.R` |
| `finbra_municipality_elemento.csv` | `fig_expenditure_composition.R` |

If any of these files are absent, `main.sh` skips the affected scripts with a clear warning and continues with the remaining outputs.

---

## Paths configuration

All paths are set in `code/utils/paths.R`. To add a new machine, add a block:

```r
} else if (Sys.getenv("USER") == "youruser") {
  dropbox_dir <- "/path/to/MiDES-data-paper-replication"
}
```

Output directories (`output/figures/`, `output/tables/`) are relative to the repository root and are created automatically.

---

## FAQ

**Where is the original data treatment code?**
The harmonization pipeline is in the Base dos Dados repository: https://github.com/basedosdados/queries-basedosdados/tree/main/models/world_wb_mides/code

**Why does PE (Pernambuco) have missing linking identifiers?**
PE's original data does not provide unique identifiers sufficient to construct `id_bd`. Consequently, PE cannot be linked across commitment/verification/payment tables.

**Why is São Paulo not in the procurement analysis?**
SP provides procurement data only from 2018 onward, so it is excluded from the procurement sample.

**Why do some regression tables go to `output/figures/` instead of `output/tables/`?**
The paper's master `.tex` file reads certain regression tables via `\input{figures/...}`. These scripts write directly to `output/figures/` to match that convention.
