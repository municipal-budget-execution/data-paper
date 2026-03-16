# Refactoring Plan — MiDES Data Paper Repository

## Goal

Transform a flat, loosely-organized collection of R scripts and Jupyter notebooks into a clean, fully-R replication package suitable for journal publication, following best practices for research code reproducibility.

**Non-goal**: change any analysis results. All outputs must match the accepted submission exactly.

---

## Proposed directory structure

```
MiDES-data-paper-repository/
├── CLAUDE.md                          ← AI instructions
├── README.md                          ← human overview (update existing)
├── plan.md                            ← this file
├── .gitignore
├── main.sh                            ← single entry point: clears output, runs everything
│
├── code/
│   ├── build/                         ← data ingestion from BigQuery/APIs
│   │   ├── ingest_bigquery.R          ← consolidates all BigQuery queries
│   │   ├── API_ComprasDados/          ← federal ComprasDados API scripts
│   │   │   ├── Extract_Licitacoes.R
│   │   │   ├── Extract_Pregoes.R
│   │   │   ├── Extract_UASG.R
│   │   │   ├── Extract_NonCompetitive.R
│   │   │   ├── AppendTransparencyData.R
│   │   │   └── BuildHomeBiasFederalEntities.R
│   │   └── queries/                   ← individual BigQuery query scripts
│   │       ├── Query_HomeBias.R
│   │       ├── Query_FederalComparison.R
│   │       └── Extract_Items_Mides.R
│   │
│   ├── analysis/                      ← one R script per figure/table group
│   │   ├── fig_validation_siconfi.R   ← Fig 3–5, A1–A4  (converted from .ipynb)
│   │   ├── fig_home_bias.R            ← Fig 6–8          (converted from .ipynb)
│   │   ├── fig_delay_payment.R        ← Fig 9, Fig A6    (from fig_reg_delay_payment.R)
│   │   ├── fig_delay_maps.R           ← Fig 10, A5       (converted from .ipynb)
│   │   ├── fig_scatter_delay_gdp.R    ← Fig 11           (split from fig_reg_delay_payment.R)
│   │   ├── fig_noncompetitive_hist.R  ← Fig A7           (from example_paper.R)
│   │   ├── fig_null_ids.R             ← Fig B1–B4        (converted from .ipynb)
│   │   ├── fig_missing_municipalities.R ← Fig B5–B6      (converted from .ipynb)
│   │   ├── fig_total_municipalities.R   ← Fig B7–B9      (converted from .ipynb)
│   │   ├── tab_descriptive_municipalities.R ← Tab 1 descriptives (converted from .ipynb)
│   │   ├── tab_descriptive_procurement.R    ← Tab 2      (converted from .ipynb)
│   │   ├── tab_descriptive_execution.R      ← Tab 3      (converted from .ipynb)
│   │   ├── tab_regressions_delay.R          ← Tab 4, 5  (split from fig_reg_delay_payment.R)
│   │   └── tab_regressions_home_bias.R      ← Home bias tables (from home_bias_regressions.R)
│   │
│   └── utils/                         ← shared helpers
│       ├── paths.R                    ← centralised path config (extract from master.R)
│       ├── packages.R                 ← single place to declare all required packages
│       ├── set_theme_ggplots.R        ← move from Functions/
│       └── pdf_table.R                ← move from Functions/
│
├── code/archive/                      ← exploratory scripts not producing paper outputs
│
└── docs/
    └── documentation_in_portuguese.pdf
```

Files **to archive** (exploratory/diagnostic, not producing paper outputs):
- `202510_MIDES_HomeBias.r` — recent exploratory work
- `ChecksParana_CommitmentTender.R` — data quality checks
- `ExamplesParanaMultipleCommitments.R` — example analysis
- `Deviations_SICONFI_Compras.R` — diagnostic
- `Aux_API_PNCP.R` — auxiliary API helper
- `WordCloud_Mides.R`, `WordCloud_Fed.R` — exploratory
- `Figure_ElectronicAuction.R` — not in final paper (verify)
- `ComparisonMIDES_Federal.do`, `Table_Uasg_comprasdados.do`, `Figure_Elemento.do`, `RDD_mayors.do` — Stata originals; converted to R (see Phase 5b), kept for reference
- All `.ipynb` files (replaced by R scripts)

---

## `main.sh` — the single entry point

`main.sh` is the **only file a replicator needs to run**. It:

1. Parses a `--redownload` flag (default: `false`)
2. If `--redownload=true`: runs `code/build/ingest_bigquery.R` (requires BigQuery auth)
3. Clears `output/figures/` and `output/tables/`
4. Runs every analysis script in `code/analysis/` in the correct order via `Rscript`
5. Prints a completion summary

```bash
# Usage
bash main.sh               # use existing data, regenerate all outputs
bash main.sh --redownload  # re-fetch data from BigQuery first, then regenerate
```

The `--redownload` flag is `false` by default because:
- The processed input CSVs are included with the replication package (or retrievable from the data repository)
- BigQuery access requires a Google Cloud project and `basedosdados` credentials
- Most replicators will just want to verify the analysis, not re-pull raw data

---

## Step-by-step execution plan

### Phase 1 — Scaffolding ✅ done
- [x] Create backup: `MiDES-data-paper-repository-backup-20260316`
- [x] Checkout branch: `refactor/clean-structure`
- [x] Update `.gitignore`
- [x] Create `CLAUDE.md`
- [x] Create `plan.md` (this file)
- [x] Commit: `chore: add CLAUDE.md, plan.md, updated .gitignore`

### Phase 2 — Create directory skeleton ✅ done
- [x] Create `code/build/API_ComprasDados/`, `code/build/queries/`
- [x] Create `code/analysis/`, `code/utils/`, `code/archive/`, `docs/`
- [x] Add `.gitkeep` in each empty directory
- [x] Commit: `chore: create directory skeleton`

### Phase 3 — Move non-analysis scripts ✅ done
- [x] Move `API_ComprasDados/*` → `code/build/API_ComprasDados/`
- [x] Move `Query_HomeBias.R`, `Query_FederalComparison.R`, `Extract_Items_Mides.R` → `code/build/queries/`
- [x] Move `Functions/set_theme_ggplots.R`, `Functions/pdf_table.R` → `code/utils/`
- [x] Move `documentation_in_portuguese.pdf` → `docs/`
- [x] Move exploratory/diagnostic scripts → `code/archive/`
- [x] Remove now-empty `Functions/` directory
- [x] Commit: `refactor: move build, utils, and archive scripts to subdirectories`

### Phase 4 — Create shared utilities ✅ done
- [x] Create `code/utils/paths.R`: extract multi-user path logic from `master.R`; define `input`, `graph_output`, `table_output`, `function_code`
- [x] Create `code/utils/packages.R`: declare all required R packages in one place; use `pacman::p_load()`
- [x] Commit: `refactor: extract shared utilities (paths, packages) to code/utils/`

### Phase 5 — Split and refactor existing R analysis scripts

For each script:
1. Place in `code/analysis/` with new name
2. Add `source(here::here("code/utils/paths.R"))` at top (use `here` package for portability)
3. Make self-contained: load its own data, produce its own outputs, save to `graph_output` / `table_output`
4. Run end-to-end and verify outputs match paper

Splits:
- `fig_reg_delay_payment.R` → **three** scripts:
  - `code/analysis/fig_delay_payment.R` — Fig 9, Fig A6
  - `code/analysis/fig_scatter_delay_gdp.R` — Fig 11
  - `code/analysis/tab_regressions_delay.R` — Tab 4, Tab 5
- `example_paper.R` → `code/analysis/fig_noncompetitive_hist.R` — Fig A7
- `home_bias_regressions.R` → `code/analysis/tab_regressions_home_bias.R`

- [x] Commit per script: `refactor: add code/analysis/<script_name>.R`

### Phase 6 — Convert Python notebooks to R ✅ done

Each notebook becomes a self-contained R script. For the conversion:
- Use `data.table` / `dplyr` for data manipulation (replacing `pandas`)
- Use `ggplot2` for all plots (replacing `matplotlib` / `seaborn`)
- Use `sf` + `ggplot2` for maps (replacing `geopandas`)
- Use `modelsummary` / `kableExtra` for tables (replacing `stargazer` or manual LaTeX)
- Apply the shared theme from `code/utils/set_theme_ggplots.R`

Conversions (notebook → R script):

| Notebook | R script | Outputs |
|---|---|---|
| `validation_siconfi_execution.ipynb` | `fig_validation_siconfi.R` | Fig 3–5, A1–A4 |
| `home_bias_firms_characteristics.ipynb` | `fig_home_bias.R` | Fig 6–8 |
| `delay_payment_maps.ipynb` | `fig_delay_maps.R` | Fig 10, A5 |
| `null_ids.ipynb` | `fig_null_ids.R` | Fig B1–B4 |
| `missing_municipalities.ipynb` | `fig_missing_municipalities.R` | Fig B5–B6 |
| `total_municipalities.ipynb` | `fig_total_municipalities.R` | Fig B7–B9 |
| `descriptive_statistics_procurement.ipynb` | `tab_descriptive_procurement.R` | Tab 2 |
| `descriptive_statistics_execution.ipynb` | `tab_descriptive_execution.R` | Tab 3 |
| `descriptive_statistics_municipalities.ipynb` | `tab_descriptive_municipalities.R` | Tab descriptives |

For each conversion:
1. Read the notebook carefully to understand the full logic
2. Write the R script with equivalent logic
3. Run against the same input data
4. Visually compare output against the accepted paper figures/tables
5. Iterate until identical

- [x] Commit per conversion: `feat: convert <notebook_name> to R`

**Correction to Phase 6 notebook mapping** — `home_bias_firms_characteristics.ipynb` was listed as "Fig 6–8" but this was wrong. Corrected mapping:
- Fig 6a/6b = waiver thresholds → `fig_waiver_thresholds.R` (from Stata, see Phase 5b)
- Fig 7 = by-state histogram → `fig_home_bias.R`
- Fig 8 = federal vs municipal scatter → `fig_home_bias_federal.R`

### Phase 5b — Convert Stata do files to R ✅ done

The four Stata do files in `code/archive/` were incorrectly classified as "exploratory". They all produce outputs read by the paper's master tex file.

| Do file | R replacement | Outputs |
|---|---|---|
| `ComparisonMIDES_Federal.do` | `code/analysis/fig_waiver_thresholds.R` | `Dahis Fig 6a.png`, `Dahis Fig 6b.png`, `distribution_tender_federal.png`, `distribution_items_federal.png` |
| `RDD_mayors.do` | `code/analysis/fig_rdd_mayors.R` | `Dahis Fig 12a.pdf`, `Dahis Fig 12b.pdf`, `tables/RDD_mayors.tex` |
| `Figure_Elemento.do` | `code/analysis/fig_expenditure_composition.R` | `composition_levels_expenditures.png` |
| `Table_Uasg_comprasdados.do` | `code/analysis/tab_uasg_esferas.R` | `tables/uasg_esferas.tex` |

Additional corrections made in this phase:
- `tab_regressions_home_bias.R` rewritten: now runs the correct **tender-level** 3-column correlates regression from `participante_cnpj.csv` (original used wrong aggregate spec). Output renamed `reg_home_bias_correlates.tex` → `output/figures/` (paper reads via `\input{figures/...}`).
- `fig_home_bias.R` updated: outputs renamed to correct filenames (`Dahis Fig 7.png`, appendix PNGs); generates LOESS scatter and by-type/by-population appendix figures.
- `fig_home_bias_federal.R` created (based on `BuildHomeBiasFederalEntities.R`): produces `Dahis Fig 8.png`, `scatter_federal_localpurchase_weighted.png`, `regression_home_bias.tex`, `regression_home_bias_weighted.tex`, `reg_home_bias_correlates_weighted.tex`, weighted histogram appendix figures — all to `output/figures/`.
- `code/utils/paths.R` updated: added `intermediate` variable pointing to `Data/Intermediate/`.
- `main.sh` updated: wires all new scripts.

- [x] Commit: `feat: convert Stata do files to R; fix home bias regression spec and output paths`

### Phase 7 — Write `main.sh` ✅ done
- [x] Write `main.sh` with `--redownload` flag logic
- [x] Wire all analysis scripts in the correct dependency order
- [ ] Test full run end-to-end
- [x] Commit: `feat: add main.sh single entry point`

### Phase 8 — Remove old master files and retire notebooks ✅ done
- [x] Archive `master.R`, `master.ipynb` → `code/archive/`
- [x] Move all `.ipynb` files to `code/archive/` (originals, for reference)
- [x] Commit: `feat: add main.sh; archive master.R, master.ipynb, and original notebooks`

### Phase 9 — Run full verification ✅ done
- [x] Run `bash main.sh` end-to-end from a clean output directory
- [x] Diff every output file against `../MiDES-data-paper-replication/WBER_Submission/FinalSubmission/figures/` and `tables/`
- [x] Fix any discrepancies (see fixes below)
- [x] Commit: `test: full end-to-end verification pass`

Fixes applied in Phase 9:
- `code/utils/packages.R`: added missing packages (`ggrepel`, `rdrobust`, `stringi`, `readxl`, `haven`, `janitor`)
- `code/analysis/fig_home_bias_federal.R`: fixed intermediate file path, column name (`modalidade`), GDP merge (use 2020 data), reduced to 2 models (year FE unidentified with single-year data), removed invalid `fixef = FALSE` from `etable()`
- `code/analysis/tab_regressions_home_bias.R`: removed invalid `fixef = FALSE` from `etable()`
- `code/analysis/tab_uasg_esferas.R`: added `tolower()` normalization for camelCase column names in `uasg.csv` and `orgaos.csv`
- `main.sh`: added graceful skips for `fig_rdd_mayors.R` and `fig_expenditure_composition.R` when intermediate data absent
- `code/analysis/fig_validation_siconfi.R`: renamed outputs to `Dahis Fig 3/4/5.pdf`
- `code/analysis/fig_delay_payment.R`: added `Dahis Fig 9a/9b.png` outputs
- `code/analysis/fig_delay_maps.R`: added `Dahis Fig 10.png` output
- `code/analysis/fig_scatter_delay_gdp.R`: added `Dahis Fig 11.png` output
- `code/analysis/fig_missing_municipalities.R`: fixed output filename (`missing_municipalities_budget_sample.pdf`)
- `code/analysis/tab_descriptive_execution.R`: fixed output filename (`descriptive_statistics_budget_execution.tex`)
- `code/analysis/tab_descriptive_procurement.R`: fixed output filename (`descriptive_statistics_procurement.tex`)

### Phase 10 — Update README ✅ done
- [x] Rewrite README.md: structure, requirements (R only, no Python), `main.sh` usage, BigQuery setup for `--redownload`
- [x] Update table/figure → script mapping
- [x] Commit: `docs: rewrite README for final replication package`

---

## Key design decisions

1. **R only**: All analysis code in R. No Python or Jupyter dependency for replicators. Eliminates the Python environment setup burden. Python notebooks moved to `code/archive/` for reference.

2. **One button**: `bash main.sh` is the entire interface. Clear outputs, run, done. No mental overhead about which script to run first.

3. **Re-download flag**: `--redownload` flag (default: false) gates the BigQuery data pull. Standard replication uses the provided processed CSVs. Advanced users who want to re-pull raw data can pass `--redownload` after setting up BigQuery credentials.

4. **Build vs Analysis separation**: `code/build/` = data ingestion (gated by `--redownload`). `code/analysis/` = the actual analysis. A reviewer can audit analysis without touching build.

5. **One output per script**: Each analysis script = one figure or one table group. Easy to trace any paper output to its source.

6. **Self-contained scripts**: Every analysis script sources `code/utils/paths.R`, loads its own data slice, produces its outputs. No shared global state.

7. **Nothing deleted**: Everything not in the analysis pipeline moves to `code/archive/`. Git history is preserved.

8. **Data never in git**: All `.csv`, `.parquet`, etc. stay in Dropbox/data repository and are gitignored.
