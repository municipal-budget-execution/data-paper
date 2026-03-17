#!/usr/bin/env bash
# main.sh — single entry point for the MiDES replication package
#
# Usage:
#   bash main.sh               # use existing processed data, regenerate all outputs
#   bash main.sh --redownload  # re-fetch raw data from BigQuery first, then regenerate
#
# The --redownload flag requires a configured Google Cloud project and
# basedosdados credentials. Default is false — processed input CSVs are
# provided with the package.

set -euo pipefail

# ---- Parse arguments ----

REDOWNLOAD=false
for arg in "$@"; do
  case "$arg" in
    --redownload) REDOWNLOAD=true ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# ---- Resolve repo root (directory containing this script) ----

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Step 1: Re-download data from BigQuery (optional) ----

if [ "$REDOWNLOAD" = true ]; then
  echo "==> [1/3] Re-downloading data from BigQuery..."
  Rscript --vanilla "$REPO_ROOT/code/build/ingest_bigquery.R"
else
  echo "==> [1/3] Skipping data download (use --redownload to re-fetch from BigQuery)"
fi

# ---- Step 2: Clear output directories ----

echo "==> [2/3] Clearing output directories..."
rm -rf "$REPO_ROOT/output/figures"
rm -rf "$REPO_ROOT/output/tables"
mkdir -p "$REPO_ROOT/output/figures"
mkdir -p "$REPO_ROOT/output/tables"

# ---- Step 3: Run all analysis scripts in dependency order ----

echo "==> [3/3] Running analysis scripts..."

ANALYSIS="$REPO_ROOT/code/analysis"

run_script() {
  local script="$1"
  echo "    --> $script"
  Rscript --vanilla "$ANALYSIS/$script"
}

# Descriptive statistics tables (no figure dependencies)
run_script "tab_descriptive_municipalities.R"
run_script "tab_descriptive_procurement.R"
run_script "tab_descriptive_execution.R"

# Validation figures
run_script "fig_validation_siconfi.R"

# Home bias figures and tables
run_script "fig_home_bias.R"
run_script "fig_home_bias_federal.R"   # needs Data/Intermediate (built by BuildHomeBiasFederalEntities.R)
run_script "tab_regressions_home_bias.R"
run_script "fig_waiver_thresholds.R"   # Fig 6a/6b; needs Data/Intermediate (licitacoes_2021 combined)

# Payment delay figures and tables
run_script "fig_delay_payment.R"
run_script "fig_delay_maps.R"
run_script "fig_scatter_delay_gdp.R"
run_script "tab_regressions_delay.R"

# Appendix figures
run_script "fig_noncompetitive_hist.R"

# Deviations: SICONFI vs. tender values (needs Data/Intermediate/siconfi_compras.csv)
SICONFI_COMPRAS="$REPO_ROOT/../MiDES-data-paper-replication/Data/Intermediate/siconfi_compras.csv"
if [ -f "$SICONFI_COMPRAS" ]; then
  run_script "fig_deviations_siconfi.R"
else
  echo "    --> fig_deviations_siconfi.R  [SKIPPED — siconfi_compras.csv not found in Data/Intermediate/]"
fi

# Deviations: Parana tender vs. commitment (needs Data/Intermediate/PR_empenho_licitacao.csv)
PR_DEVIATIONS="$REPO_ROOT/../MiDES-data-paper-replication/Data/Intermediate/PR_empenho_licitacao.csv"
if [ -f "$PR_DEVIATIONS" ]; then
  run_script "fig_deviations_parana.R"
else
  echo "    --> fig_deviations_parana.R  [SKIPPED — PR_empenho_licitacao.csv not found in Data/Intermediate/]"
fi

# Word clouds (needs Data/Raw/mides_2021_items.csv and Data/Intermediate federal RDS)
run_script "fig_wordclouds.R"

# Political economy (RDD)
MAYORS_DTA="$REPO_ROOT/../MiDES-data-paper-replication/Data/Intermediate/mayors.dta"
if [ -f "$MAYORS_DTA" ]; then
  run_script "fig_rdd_mayors.R"        # Fig 12 + Tab 6
else
  echo "    --> fig_rdd_mayors.R  [SKIPPED — mayors.dta not found at Data/Intermediate/mayors.dta]"
fi

# Appendix: expenditure composition and procurement platform coverage
FINBRA_STATE="$REPO_ROOT/../MiDES-data-paper-replication/Data/Intermediate/finbra_state_elemento.csv"
if [ -f "$FINBRA_STATE" ]; then
  run_script "fig_expenditure_composition.R"  # needs Data/Intermediate FINBRA files
else
  echo "    --> fig_expenditure_composition.R  [SKIPPED — FINBRA files not found in Data/Intermediate/]"
fi
run_script "tab_uasg_esferas.R"

# Data quality appendix
run_script "fig_null_ids.R"
run_script "fig_missing_municipalities.R"
run_script "fig_total_municipalities.R"

# ---- Done ----

echo ""
echo "============================================================"
echo "  Replication complete."
echo "  Figures -> $REPO_ROOT/output/figures/"
echo "  Tables  -> $REPO_ROOT/output/tables/"
echo "============================================================"
