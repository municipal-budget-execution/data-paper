# CLAUDE.md — Instructions for Claude Code

This file provides guidance for Claude when working in this repository.

## Project overview

Replication package for the paper **"MiDES: New Data and Facts from Local Procurement and Budget Execution in Brazil"** (World Bank Economic Review, accepted).

The goal is reproducibility: anyone with access to the data should be able to run the code and regenerate every table and figure in the paper exactly.

## Repository layout

```
MiDES-data-paper-repository/
├── CLAUDE.md                  ← this file
├── README.md                  ← human-readable overview
├── plan.md                    ← refactoring plan
├── .gitignore
├── master.R                   ← runs all R analysis scripts
├── master.ipynb               ← runs all Python analysis notebooks
├── code/
│   ├── build/                 ← data extraction / API queries (not part of reproducibility core)
│   │   └── API_ComprasDados/
│   ├── analysis/              ← one script per table/figure
│   │   ├── R/
│   │   └── python/
│   └── utils/                 ← shared functions (theming, paths, helpers)
└── docs/
    └── documentation_in_portuguese.pdf
```

Data files are stored outside the repo (Dropbox) and are **never committed to git**.

## Paper → code mapping

The paper lives in `../MiDES-data-paper-replication/WBER_Submission/FinalSubmission/`.

| Output | Script |
|--------|--------|
| Fig 3–5, A1–A4 | `code/analysis/python/fig_validation_siconfi.ipynb` |
| Fig 6–8 | `code/analysis/python/fig_home_bias.ipynb` |
| Fig 9, A6 | `code/analysis/R/fig_delay_payment.R` |
| Fig 10, A5 | `code/analysis/python/fig_delay_maps.ipynb` |
| Fig 11 | `code/analysis/R/fig_scatter_delay_gdp.R` |
| Fig A7 | `code/analysis/R/fig_noncompetitive_hist.R` |
| Fig B1–B4 | `code/analysis/python/fig_null_ids.ipynb` |
| Fig B5–B6 | `code/analysis/python/fig_missing_municipalities.ipynb` |
| Fig B7–B9 | `code/analysis/python/fig_total_municipalities.ipynb` |
| Tab 2 | `code/analysis/python/tab_descriptive_procurement.ipynb` |
| Tab 3 | `code/analysis/python/tab_descriptive_execution.ipynb` |
| Tab 4–5 | `code/analysis/R/tab_regressions_delay.R` |
| Home bias regs | `code/analysis/R/tab_regressions_home_bias.R` |

## Paths convention

All path configuration lives in `code/utils/paths.R` (R) and the top cell of each notebook (Python). Never hardcode paths in analysis scripts. The master files set `dropbox_dir` and `github_dir` based on `Sys.getenv("USER")`.

Key directories:
- **Input data**: `{dropbox_dir}/Data/Raw/`
- **Figures output**: `{dropbox_dir}/Output/Figures/`
- **Tables output**: `{dropbox_dir}/Output/Tables/`

## Coding conventions

- **R**: use `data.table` for data manipulation, `ggplot2` for figures, `modelsummary` for tables. Load packages via `pacman::p_load()`.
- **Python**: use `pandas`, `matplotlib`/`seaborn`, standard scientific stack.
- Each analysis script is self-contained: it loads its own data, produces its output, and saves to the output directory. Do not have scripts depend on global state from other scripts.
- Use the shared ggplot2 theme from `code/utils/set_theme_ggplots.R` for all R figures.

## What NOT to do

- Do not commit data files (csv, parquet, dta, xlsx). They live in Dropbox.
- Do not commit output files (figures, tables). They are generated.
- Do not change the paper tex files — they live in a separate directory (`MiDES-data-paper-replication`).
- Do not alter the substance of any analysis. Refactoring is structural only.

## Verification rule

After any refactoring, run the affected script end-to-end and visually compare outputs to those in `../MiDES-data-paper-replication/WBER_Submission/FinalSubmission/figures/` and `tables/`. Results must be byte-identical or visually identical.

## Git discipline

- Work on branch `refactor/clean-structure`.
- Make atomic commits: one logical change per commit.
- Commit message style: `refactor: <what changed>` or `chore: <what changed>`.
- Never commit to `main` directly.
