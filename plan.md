# Refactoring Plan — MiDES Data Paper Repository

## Goal

Transform a flat, loosely-organized collection of R scripts and Jupyter notebooks into a clean replication package suitable for journal publication, following best practices for research code reproducibility.

**Non-goal**: change any analysis results. All outputs must match the accepted submission exactly.

---

## Proposed directory structure

```
MiDES-data-paper-repository/
├── CLAUDE.md                          ← AI instructions
├── README.md                          ← human overview (update existing)
├── plan.md                            ← this file
├── .gitignore                         ← updated
├── master.R                           ← orchestrates all R scripts
├── master.ipynb                       ← orchestrates all Python notebooks
│
├── code/
│   ├── build/                         ← data extraction (not part of reproducibility core)
│   │   ├── API_ComprasDados/          ← federal API extraction scripts (move from root)
│   │   │   ├── Extract_Licitacoes.R
│   │   │   ├── Extract_Pregoes.R
│   │   │   ├── Extract_UASG.R
│   │   │   ├── Extract_NonCompetitive.R
│   │   │   ├── AppendTransparencyData.R
│   │   │   └── BuildHomeBiasFederalEntities.R
│   │   └── queries/                   ← BigQuery query scripts (move from root)
│   │       ├── Query_HomeBias.R
│   │       ├── Query_FederalComparison.R
│   │       └── Extract_Items_Mides.R
│   │
│   ├── analysis/                      ← one script per table/figure group
│   │   ├── R/
│   │   │   ├── fig_delay_payment.R        ← Fig 9, Fig A6        (from fig_reg_delay_payment.R)
│   │   │   ├── fig_scatter_delay_gdp.R    ← Fig 11               (split from fig_reg_delay_payment.R)
│   │   │   ├── fig_noncompetitive_hist.R  ← Fig A7               (from example_paper.R)
│   │   │   ├── tab_regressions_delay.R    ← Tab 4, Tab 5         (split from fig_reg_delay_payment.R)
│   │   │   └── tab_regressions_home_bias.R ← Home bias tables    (from home_bias_regressions.R)
│   │   └── python/
│   │       ├── fig_validation_siconfi.ipynb      ← Fig 3–5, A1–A4
│   │       ├── fig_home_bias.ipynb               ← Fig 6–8
│   │       ├── fig_delay_maps.ipynb              ← Fig 10, A5
│   │       ├── fig_null_ids.ipynb                ← Fig B1–B4
│   │       ├── fig_missing_municipalities.ipynb  ← Fig B5–B6
│   │       ├── fig_total_municipalities.ipynb    ← Fig B7–B9
│   │       ├── tab_descriptive_procurement.ipynb ← Tab 2
│   │       └── tab_descriptive_execution.ipynb   ← Tab 3
│   │
│   └── utils/                         ← shared helpers
│       ├── paths.R                    ← centralised path config (extract from master.R)
│       ├── set_theme_ggplots.R        ← move from Functions/
│       └── pdf_table.R                ← move from Functions/
│
└── docs/
    └── documentation_in_portuguese.pdf   ← move from root
```

Files **to archive / not migrate** (exploratory/diagnostic, not part of paper):
- `202510_MIDES_HomeBias.r` — recent exploratory script, not producing paper outputs
- `ChecksParana_CommitmentTender.R` — data quality checks, not paper outputs
- `ExamplesParanaMultipleCommitments.R` — example analysis, not paper outputs
- `Deviations_SICONFI_Compras.R` — diagnostic, not directly producing paper tables
- `Aux_API_PNCP.R` — auxiliary API helper
- `WordCloud_Mides.R`, `WordCloud_Fed.R` — exploratory
- `Figure_ElectronicAuction.R` — unclear if in paper
- `ComparisonMIDES_Federal.do`, `Table_Uasg_comprasdados.do`, `Figure_Elemento.do` — Stata scripts; verify if any produce paper outputs
- `Download_comprasdados.ipynb` — data ingestion (build step, not analysis)

These go to `code/archive/` so nothing is deleted.

---

## Step-by-step execution plan

### Phase 1 — Scaffolding (done in this session)
- [x] Create backup: `MiDES-data-paper-repository-backup-YYYYMMDD`
- [x] Checkout branch: `refactor/clean-structure`
- [x] Update `.gitignore`
- [x] Create `CLAUDE.md`
- [x] Create `plan.md` (this file)
- [ ] Commit: `chore: add CLAUDE.md, plan.md, updated .gitignore`

### Phase 2 — Create directory skeleton
- [ ] Create `code/build/API_ComprasDados/`, `code/build/queries/`
- [ ] Create `code/analysis/R/`, `code/analysis/python/`
- [ ] Create `code/utils/`, `code/archive/`, `docs/`
- [ ] Commit: `chore: create directory skeleton`

### Phase 3 — Move non-analysis scripts
- [ ] Move `API_ComprasDados/*` → `code/build/API_ComprasDados/`
- [ ] Move `Query_HomeBias.R`, `Query_FederalComparison.R`, `Extract_Items_Mides.R` → `code/build/queries/`
- [ ] Move `Functions/set_theme_ggplots.R`, `Functions/pdf_table.R` → `code/utils/`
- [ ] Move `documentation_in_portuguese.pdf` → `docs/`
- [ ] Move exploratory/diagnostic scripts → `code/archive/`
- [ ] Commit: `refactor: move build, utils, and archive scripts to subdirectories`

### Phase 4 — Extract paths into utils/paths.R
- [ ] Create `code/utils/paths.R` with the multi-user path logic from `master.R`
- [ ] Update `master.R` to `source("code/utils/paths.R")` instead of inline logic
- [ ] Commit: `refactor: extract path configuration to code/utils/paths.R`

### Phase 5 — Split and move R analysis scripts

For each script below, the work is:
1. Copy to new location with new name
2. Add `source()` for `code/utils/paths.R` and `code/utils/set_theme_ggplots.R` at the top
3. Remove any global-state dependencies (inline the data loading needed)
4. Run it end-to-end and verify outputs match paper

Scripts to split/move:
- `fig_reg_delay_payment.R` → three scripts:
  - `code/analysis/R/fig_delay_payment.R` (Fig 9, Fig A6)
  - `code/analysis/R/fig_scatter_delay_gdp.R` (Fig 11)
  - `code/analysis/R/tab_regressions_delay.R` (Tab 4, Tab 5)
- `example_paper.R` → `code/analysis/R/fig_noncompetitive_hist.R` (Fig A7)
- `home_bias_regressions.R` → `code/analysis/R/tab_regressions_home_bias.R`
- [ ] Commit each split separately: `refactor: split fig_reg_delay_payment.R into atomic scripts`

### Phase 6 — Rename and move Python notebooks

Rename for clarity and move to `code/analysis/python/`:
- `validation_siconfi_execution.ipynb` → `fig_validation_siconfi.ipynb`
- `home_bias_firms_characteristics.ipynb` → `fig_home_bias.ipynb`
- `delay_payment_maps.ipynb` → `fig_delay_maps.ipynb`
- `null_ids.ipynb` → `fig_null_ids.ipynb`
- `missing_municipalities.ipynb` → `fig_missing_municipalities.ipynb`
- `total_municipalities.ipynb` → `fig_total_municipalities.ipynb`
- `descriptive_statistics_procurement.ipynb` → `tab_descriptive_procurement.ipynb`
- `descriptive_statistics_execution.ipynb` → `tab_descriptive_execution.ipynb`
- `descriptive_statistics_municipalities.ipynb` → `tab_descriptive_municipalities.ipynb`

Move data ingestion to build:
- `Download_comprasdados.ipynb` → `code/build/Download_comprasdados.ipynb`

- [ ] Commit: `refactor: rename and move Python notebooks to code/analysis/python/`

### Phase 7 — Update master files
- [ ] Update `master.R` to source scripts from their new locations
- [ ] Update `master.ipynb` to reference notebooks from their new locations
- [ ] Commit: `refactor: update master files to reference new script locations`

### Phase 8 — Run and verify
- [ ] Run `master.R` end-to-end; compare all R outputs against submission files
- [ ] Run `master.ipynb` end-to-end; compare all Python outputs against submission files
- [ ] Fix any discrepancies
- [ ] Commit: `test: verify all outputs match submission after refactoring`

### Phase 9 — Update README
- [ ] Rewrite README.md to reflect new structure
- [ ] Update the table/figure → file mapping table
- [ ] Commit: `docs: update README for new structure`

---

## Key design decisions

1. **Build vs Analysis separation**: Scripts that download/extract data from BigQuery or APIs are `build`. Scripts that load already-processed data to produce paper outputs are `analysis`. The replication package reviewer only needs to run `analysis`.

2. **One output per script**: Each analysis script produces one figure or one table (or a tightly related group like Fig 3–5 which come from one notebook). This makes it easy to trace paper outputs to code.

3. **Self-contained scripts**: Each analysis script sources `code/utils/paths.R` and loads its own data. No global state from master files flows into analysis scripts.

4. **Nothing deleted**: Exploratory and diagnostic scripts move to `code/archive/` so the git history is clean and nothing is lost.

5. **Data never in git**: All `.csv`, `.parquet`, etc. stay in Dropbox and are gitignored.
