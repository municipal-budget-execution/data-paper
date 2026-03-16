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
| Figures | `ggplot2`, `ggpubr`, `ggtext` |
| Maps | `sf`, `geobr` |
| Econometrics | `fixest`, `binsreg` |
| Tables | `kableExtra`, `tinytex` |

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

### Figures

| Figure | Description | Script |
|---|---|---|
| Fig 1 | Coverage map | *manually created* |
| Fig 2 | Procurement process diagram | *manually created* |
| Fig 3 | Validation — commitment | `code/analysis/fig_validation_siconfi.R` |
| Fig 4 | Validation — verification | `code/analysis/fig_validation_siconfi.R` |
| Fig 5 | Validation — payment | `code/analysis/fig_validation_siconfi.R` |
| Fig 6 | Home bias: competitive vs. non-competitive | `code/analysis/fig_home_bias.R` |
| Fig 7 | Home bias: by tender type | `code/analysis/fig_home_bias.R` |
| Fig 8 | Home bias: by population size | `code/analysis/fig_home_bias.R` |
| Fig 9 | Distribution of payment delays | `code/analysis/fig_delay_payment.R` |
| Fig 10 | Map: weighted average payment delay (2018) | `code/analysis/fig_delay_maps.R` |
| Fig 11 | Scatter: payment delay vs. GDP per capita | `code/analysis/fig_scatter_delay_gdp.R` |
| Fig A1 | Validation — commitment by function | `code/analysis/fig_validation_siconfi.R` |
| Fig A2 | Validation — verification by function | `code/analysis/fig_validation_siconfi.R` |
| Fig A3 | Validation — payment by function | `code/analysis/fig_validation_siconfi.R` |
| Fig A4 | Validation — payment across years (PR, MG) | `code/analysis/fig_validation_siconfi.R` |
| Fig A5 | Map: share of payments > 30 days (2018) | `code/analysis/fig_delay_maps.R` |
| Fig A6 | CDF of late payments across years | `code/analysis/fig_delay_payment.R` |
| Fig A7 | Histogram: non-competitive tender share | `code/analysis/fig_noncompetitive_hist.R` |
| Fig B1 | Missing tender identifiers | `code/analysis/fig_null_ids.R` |
| Fig B2 | Missing commitment identifiers | `code/analysis/fig_null_ids.R` |
| Fig B3 | Missing verification identifiers | `code/analysis/fig_null_ids.R` |
| Fig B4 | Missing payment identifiers | `code/analysis/fig_null_ids.R` |
| Fig B5 | Missing municipalities: procurement | `code/analysis/fig_missing_municipalities.R` |
| Fig B6 | Missing municipalities: budget execution | `code/analysis/fig_missing_municipalities.R` |
| Fig B7 | Municipality count: commitments | `code/analysis/fig_total_municipalities.R` |
| Fig B8 | Municipality count: verifications | `code/analysis/fig_total_municipalities.R` |
| Fig B9 | Municipality count: payments | `code/analysis/fig_total_municipalities.R` |

### Tables

| Table | Description | Script |
|---|---|---|
| Tab 1 | Procurement and budget execution coverage | *manually created* |
| Tab 2 | Descriptive statistics — procurement | `code/analysis/tab_descriptive_procurement.R` |
| Tab 3 | Descriptive statistics — budget execution | `code/analysis/tab_descriptive_execution.R` |
| Tab 4 | Correlates of payment delays | `code/analysis/tab_regressions_delay.R` |
| Tab 5 | Correlates of SICONFI deviations | `code/analysis/tab_regressions_delay.R` |
| Tab A1 | Procurement and budget execution sources | *manually created* |
| Tab A2 | Procurement methods | *manually created* |
| Tab B1 | Limitations — budget execution | *manually created* |
| Tab B2 | Limitations — procurement | *manually created* |
| — | Municipality descriptive statistics | `code/analysis/tab_descriptive_municipalities.R` |
| — | Home bias regressions | `code/analysis/tab_regressions_home_bias.R` |

---

## Data

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
