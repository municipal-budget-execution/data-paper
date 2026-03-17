# code/build/ingest_bigquery.R
#
# Downloads all BigQuery-originated datasets used by the MiDES replication
# package and writes them to Data/Intermediate/BigQuery/.
#
# Called by main.sh --redownload.  Requires:
#   - A Google Cloud project with billing enabled
#   - basedosdados R package authenticated (run basedosdados::bdm_auth() once)
#   - The BILLING_PROJECT environment variable set, OR edit PROJECT_ID below
#
# Usage (from repo root):
#   Rscript --vanilla code/build/ingest_bigquery.R
#
# All queries were recovered from the original Python notebooks in code/archive/.
# Files whose queries could not be fully recovered are marked [STUB] — those
# CSVs must be reproduced manually or from the original build environment.

source(here::here("code/utils/paths.R"))

pacman::p_load(
  "basedosdados", "data.table", "bigrquery",
  install = TRUE, character.only = TRUE
)

# ---- Project ID ----
# Set via environment variable or hard-code your GCP project below.
PROJECT_ID <- Sys.getenv("BILLING_PROJECT",
                          unset = "budget-execution-procurement")
basedosdados::set_billing_id(PROJECT_ID)

# Helper: run SQL and save to bigquery/
bq_save <- function(sql, filename) {
  cat("  Querying:", filename, "...\n")
  dt <- setDT(basedosdados::read_sql(sql))
  fwrite(dt, file.path(bigquery, filename))
  cat("  Saved:", filename, "(", nrow(dt), "rows )\n")
}

dir.create(bigquery, recursive = TRUE, showWarnings = FALSE)

# ===========================================================================
# 1. PROCUREMENT DATA  (basedosdados.world_wb_mides.licitacao*)
# ===========================================================================

# ---- participante_cnpj.csv ----
# licitacao_participante joined with licitacao (modalidade) and CNPJ registry.
# Original query from code/archive/202510_MIDES_HomeBias.r / Query_HomeBias.R.
bq_save("
SELECT
    a.*,
    l.modalidade,
    b.data,
    b.cnpj,
    b.id_municipio   AS id_municipio_1,
    b.data_inicio_atividade,
    b.sigla_uf       AS sigla_uf_1,
    b.cnpj_basico,
    b.identificador_matriz_filial,
    s.opcao_simples,
    s.opcao_mei
FROM (
    SELECT *
    FROM `basedosdados.world_wb_mides.licitacao_participante`
    WHERE id_licitacao_bd IS NOT NULL
) a
LEFT JOIN (
    SELECT modalidade, id_licitacao_bd
    FROM `basedosdados.world_wb_mides.licitacao`
    WHERE id_licitacao_bd IS NOT NULL
) l ON a.id_licitacao_bd = l.id_licitacao_bd
LEFT JOIN (
    SELECT
        CAST(cnpj AS STRING) AS cnpj,
        cnpj_basico,
        id_municipio,
        sigla_uf,
        identificador_matriz_filial,
        data_inicio_atividade,
        MAX(data) AS data
    FROM `basedosdados.br_me_cnpj.estabelecimentos`
    GROUP BY cnpj, cnpj_basico, id_municipio, sigla_uf,
             data_inicio_atividade, identificador_matriz_filial
) b ON CAST(a.documento AS STRING) = b.cnpj
LEFT JOIN `basedosdados.br_me_cnpj.simples` s
    ON b.cnpj_basico = s.cnpj_basico
WHERE a.tipo = '1'
", "participante_cnpj.csv")

# ---- mides_2021_tenders.csv ----
# 2021 municipal tenders (for comparison with federal data).
# From code/build/queries/Query_FederalComparison.R.
bq_save("
SELECT sigla_uf, id_municipio, id_licitacao_bd, descricao_objeto,
       modalidade, valor_corrigido, valor_orcamento
FROM `basedosdados.world_wb_mides.licitacao`
WHERE ano = 2021
", "mides_2021_tenders.csv")

# ---- data_histogram_licitacao.csv ----
# Municipality-level share of non-competitive tenders and count.
# From code/archive/example_paper.R.
bq_save("
SELECT
    id_municipio,
    ano,
    AVG(CASE WHEN modalidade = '8' OR modalidade = '10'
             THEN 1 ELSE 0 END) AS share_discretion,
    COUNT(id_licitacao_bd)      AS count
FROM `basedosdados.world_wb_mides.licitacao`
GROUP BY id_municipio, ano
", "data_histogram_licitacao.csv")

# ---- licitacao_stats_uf.csv  /  licitacao_share_valor_uf.csv ----
# [STUB] Procurement count and value shares by state.
# Original query is in code/archive/descriptive_statistics_procurement.ipynb
# (Python notebook — query not yet ported to R).
cat("  [STUB] licitacao_stats_uf.csv — see descriptive_statistics_procurement.ipynb\n")
cat("  [STUB] licitacao_share_valor_uf.csv — see descriptive_statistics_procurement.ipynb\n")

# ---- merge_licitacao_item.csv  /  merge_licitacao_participante.csv ----
# [STUB] Tender-item and tender-participant aggregate joins.
cat("  [STUB] merge_licitacao_item.csv — see descriptive_statistics_procurement.ipynb\n")
cat("  [STUB] merge_licitacao_participante.csv — see descriptive_statistics_procurement.ipynb\n")

# ---- licitacao_participante_stats.csv  /  licitacao_participante_stats_uf.csv ----
# [STUB] Participant-level statistics.
cat("  [STUB] licitacao_participante_stats.csv — see descriptive_statistics_procurement.ipynb\n")
cat("  [STUB] licitacao_participante_stats_uf.csv — see descriptive_statistics_procurement.ipynb\n")

# ---- licitacao.csv ----
# [STUB] Full tender table — large; query from descriptive_statistics_procurement.ipynb.
cat("  [STUB] licitacao.csv — see descriptive_statistics_procurement.ipynb\n")

# ---- home_bias.csv ----
# [STUB] Municipality-year home bias metrics derived from participante_cnpj.
# Query not preserved; regenerate from participante_cnpj.csv using the
# aggregation logic in code/archive/202510_MIDES_HomeBias.r.
cat("  [STUB] home_bias.csv — regenerate from participante_cnpj.csv\n")

# ===========================================================================
# 2. BUDGET EXECUTION DATA  (basedosdados.world_wb_mides.empenho / liquidacao / pagamento)
# ===========================================================================

# ---- full_budget_execution_index.csv ----
# [STUB] Municipality-year panel with payment delay, GDP, population, and
# SICONFI deviation proportions.  Complex multi-table build —
# see code/archive/master.R and descriptive_statistics_execution.ipynb.
cat("  [STUB] full_budget_execution_index.csv — see master.R / descriptive_statistics_execution.ipynb\n")

# ---- empenho.csv / liquidacao.csv / pagamento.csv ----
# [STUB] State-level summaries of commitment, verification, payment records.
# See code/archive/descriptive_statistics_execution.ipynb.
cat("  [STUB] empenho.csv — see descriptive_statistics_execution.ipynb\n")
cat("  [STUB] liquidacao.csv — see descriptive_statistics_execution.ipynb\n")
cat("  [STUB] pagamento.csv — see descriptive_statistics_execution.ipynb\n")
cat("  [STUB] empenho_liquidacao.csv — see descriptive_statistics_execution.ipynb\n")
cat("  [STUB] empenho_pagamento.csv — see descriptive_statistics_execution.ipynb\n")
cat("  [STUB] total_pagamento_ano.csv — see descriptive_statistics_execution.ipynb\n")
cat("  [STUB] empenho_pe.csv / liq_pag_pe.csv — PE state; see descriptive_statistics_execution.ipynb\n")

# ===========================================================================
# 3. SICONFI VALIDATION  (cross-year SICONFI comparison)
# ===========================================================================

# ---- commitment_municipality_year.csv ----
# % difference between MiDES commitments and SICONFI, by municipality-year.
# From code/archive/validation_siconfi_execution.ipynb.
bq_save("
WITH commitment AS (
  SELECT ano, id_municipio,
         SUM(valor_final) AS total_commitment
  FROM `basedosdados.world_wb_mides.empenho`
  WHERE ano >= 2003
  GROUP BY 1, 2
),
siconfi AS (
  SELECT ano, sigla_uf, id_municipio,
         SUM(valor) AS total_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_orcamentarias`
  WHERE sigla_uf IN ('CE','MG','PB','PE','PR','RS','SP')
    AND ano >= 2003
    AND estagio_bd = 'Despesas Empenhadas'
    AND conta_bd  = 'Despesas Orçamentárias'
  GROUP BY 1, 2, 3
)
SELECT e.ano, sigla_uf, e.id_municipio,
       total_commitment, total_siconfi,
       ROUND(total_commitment - total_siconfi, 2)                 AS variation,
       100.0 * (total_commitment - total_siconfi) / total_commitment AS proportion
FROM commitment e
LEFT JOIN siconfi s ON e.ano = s.ano AND e.id_municipio = s.id_municipio
WHERE total_siconfi IS NOT NULL
  AND total_commitment <> 0
", "commitment_municipality_year.csv")

# ---- commitment_function_municipality_year.csv ----
bq_save("
WITH commitment AS (
  SELECT ano, sigla_uf, id_municipio, funcao,
         SUM(valor_final) AS total_commitment
  FROM `basedosdados.world_wb_mides.empenho`
  GROUP BY 1, 2, 3, 4
),
siconfi AS (
  SELECT ano, sigla_uf, id_municipio,
         CASE
           WHEN UPPER(conta_bd) = 'LEGISLATIVA'             THEN '1'
           WHEN UPPER(conta_bd) = 'JUDICIÁRIA'              THEN '2'
           WHEN UPPER(conta_bd) = 'ESSENCIAL À JUSTIÇA'     THEN '3'
           WHEN UPPER(conta_bd) = 'ADMINISTRAÇÃO'           THEN '4'
           WHEN UPPER(conta_bd) = 'DEFESA NACIONAL'         THEN '5'
           WHEN UPPER(conta_bd) = 'SEGURANÇA PÚBLICA'       THEN '6'
           WHEN UPPER(conta_bd) = 'RELAÇÕES EXTERIORES'     THEN '7'
           WHEN UPPER(conta_bd) = 'ASSISTÊNCIA SOCIAL'      THEN '8'
           WHEN UPPER(conta_bd) = 'PREVIDÊNCIA SOCIAL'      THEN '9'
           WHEN UPPER(conta_bd) = 'SAÚDE'                   THEN '10'
           WHEN UPPER(conta_bd) = 'TRABALHO'                THEN '11'
           WHEN UPPER(conta_bd) = 'EDUCAÇÃO'                THEN '12'
           WHEN UPPER(conta_bd) = 'CULTURA'                 THEN '13'
           WHEN UPPER(conta_bd) = 'DIREITOS DA CIDADANIA'   THEN '14'
           WHEN UPPER(conta_bd) = 'URBANISMO'               THEN '15'
           WHEN UPPER(conta_bd) = 'HABITAÇÃO'               THEN '16'
           WHEN UPPER(conta_bd) = 'SANEAMENTO'              THEN '17'
           WHEN UPPER(conta_bd) = 'GESTÃO AMBIENTAL'        THEN '18'
           WHEN UPPER(conta_bd) = 'CIÊNCIA E TECNOLOGIA'    THEN '19'
           WHEN UPPER(conta_bd) = 'AGRICULTURA'             THEN '20'
           WHEN UPPER(conta_bd) = 'ORGANIZAÇÃO AGRÁRIA'     THEN '21'
           WHEN UPPER(conta_bd) = 'INDÚSTRIA'               THEN '22'
           WHEN UPPER(conta_bd) = 'COMÉRCIO E SERVIÇOS'     THEN '23'
           WHEN UPPER(conta_bd) = 'COMUNICAÇÕES'            THEN '24'
           WHEN UPPER(conta_bd) = 'ENERGIA'                 THEN '25'
           WHEN UPPER(conta_bd) = 'TRANSPORTE'              THEN '26'
           WHEN UPPER(conta_bd) = 'DESPORTO E LAZER'        THEN '27'
           WHEN UPPER(conta_bd) = 'ENCARGOS ESPECIAIS'      THEN '28'
           WHEN UPPER(conta_bd) = 'RESERVA DE CONTINGÊNCIA' THEN '99'
         END AS funcao,
         SUM(valor) AS total_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_funcao`
  WHERE sigla_uf IN ('CE','MG','PB','PE','PR','RS','SP')
    AND estagio_bd = 'Despesas Empenhadas'
  GROUP BY 1, 2, 3, 4
)
SELECT e.ano, e.sigla_uf, e.id_municipio, e.funcao,
       total_commitment, total_siconfi,
       ROUND(total_commitment - total_siconfi, 2)                 AS variation,
       100.0 * (total_commitment - total_siconfi) / total_commitment AS proportion
FROM commitment e
LEFT JOIN siconfi s
    ON e.ano = s.ano AND e.sigla_uf = s.sigla_uf
   AND e.id_municipio = s.id_municipio AND e.funcao = s.funcao
WHERE total_siconfi IS NOT NULL AND total_commitment <> 0
ORDER BY variation DESC
", "commitment_function_municipality_year.csv")

# ---- verification_municipality_year.csv ----
bq_save("
WITH verification AS (
  SELECT ano, id_municipio,
         SUM(valor_final) AS total_verification
  FROM `basedosdados.world_wb_mides.liquidacao`
  WHERE ano >= 2003
  GROUP BY 1, 2
),
siconfi AS (
  SELECT ano, sigla_uf, id_municipio,
         SUM(valor) AS total_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_orcamentarias`
  WHERE sigla_uf IN ('CE','MG','PB','PE','PR','RS','SP')
    AND ano >= 2003
    AND estagio_bd = 'Despesas Liquidadas'
    AND conta_bd  = 'Despesas Orçamentárias'
  GROUP BY 1, 2, 3
)
SELECT e.ano, sigla_uf, e.id_municipio,
       total_verification, total_siconfi,
       ROUND(total_verification - total_siconfi, 2)                    AS variation,
       100.0 * (total_verification - total_siconfi) / total_verification AS proportion
FROM verification e
LEFT JOIN siconfi s ON e.ano = s.ano AND e.id_municipio = s.id_municipio
WHERE total_siconfi IS NOT NULL AND total_verification <> 0
", "verification_municipality_year.csv")

# ---- verification_function_municipality_year.csv ----
bq_save("
WITH verification AS (
  SELECT id_empenho_bd, SUM(valor_final) AS total_verification
  FROM `basedosdados.world_wb_mides.liquidacao`
  GROUP BY 1
  HAVING id_empenho_bd IS NOT NULL
),
commitment AS (
  SELECT ano, sigla_uf, id_municipio, id_empenho_bd, funcao,
         SUM(valor_final) AS total_commitment
  FROM `basedosdados.world_wb_mides.empenho`
  GROUP BY 1, 2, 3, 4, 5
  HAVING id_empenho_bd IS NOT NULL
),
verification_function AS (
  SELECT ano, sigla_uf, id_municipio, funcao,
         SUM(v.total_verification) AS total_verification
  FROM commitment c
  LEFT JOIN verification v ON c.id_empenho_bd = v.id_empenho_bd
  GROUP BY 1, 2, 3, 4
),
siconfi AS (
  SELECT ano, sigla_uf, id_municipio,
         CASE
           WHEN UPPER(conta_bd) = 'LEGISLATIVA'             THEN '1'
           WHEN UPPER(conta_bd) = 'JUDICIÁRIA'              THEN '2'
           WHEN UPPER(conta_bd) = 'ESSENCIAL À JUSTIÇA'     THEN '3'
           WHEN UPPER(conta_bd) = 'ADMINISTRAÇÃO'           THEN '4'
           WHEN UPPER(conta_bd) = 'DEFESA NACIONAL'         THEN '5'
           WHEN UPPER(conta_bd) = 'SEGURANÇA PÚBLICA'       THEN '6'
           WHEN UPPER(conta_bd) = 'RELAÇÕES EXTERIORES'     THEN '7'
           WHEN UPPER(conta_bd) = 'ASSISTÊNCIA SOCIAL'      THEN '8'
           WHEN UPPER(conta_bd) = 'PREVIDÊNCIA SOCIAL'      THEN '9'
           WHEN UPPER(conta_bd) = 'SAÚDE'                   THEN '10'
           WHEN UPPER(conta_bd) = 'TRABALHO'                THEN '11'
           WHEN UPPER(conta_bd) = 'EDUCAÇÃO'                THEN '12'
           WHEN UPPER(conta_bd) = 'CULTURA'                 THEN '13'
           WHEN UPPER(conta_bd) = 'DIREITOS DA CIDADANIA'   THEN '14'
           WHEN UPPER(conta_bd) = 'URBANISMO'               THEN '15'
           WHEN UPPER(conta_bd) = 'HABITAÇÃO'               THEN '16'
           WHEN UPPER(conta_bd) = 'SANEAMENTO'              THEN '17'
           WHEN UPPER(conta_bd) = 'GESTÃO AMBIENTAL'        THEN '18'
           WHEN UPPER(conta_bd) = 'CIÊNCIA E TECNOLOGIA'    THEN '19'
           WHEN UPPER(conta_bd) = 'AGRICULTURA'             THEN '20'
           WHEN UPPER(conta_bd) = 'ORGANIZAÇÃO AGRÁRIA'     THEN '21'
           WHEN UPPER(conta_bd) = 'INDÚSTRIA'               THEN '22'
           WHEN UPPER(conta_bd) = 'COMÉRCIO E SERVIÇOS'     THEN '23'
           WHEN UPPER(conta_bd) = 'COMUNICAÇÕES'            THEN '24'
           WHEN UPPER(conta_bd) = 'ENERGIA'                 THEN '25'
           WHEN UPPER(conta_bd) = 'TRANSPORTE'              THEN '26'
           WHEN UPPER(conta_bd) = 'DESPORTO E LAZER'        THEN '27'
           WHEN UPPER(conta_bd) = 'ENCARGOS ESPECIAIS'      THEN '28'
           WHEN UPPER(conta_bd) = 'RESERVA DE CONTINGÊNCIA' THEN '99'
         END AS funcao,
         SUM(valor) AS total_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_funcao`
  WHERE ano >= 2003
    AND sigla_uf IN ('CE','MG','PB','PR','RS','SP')   -- PE excluded (no id_empenho_bd)
    AND estagio_bd = 'Despesas Liquidadas'
  GROUP BY 1, 2, 3, 4
)
SELECT e.ano, e.sigla_uf, e.id_municipio, e.funcao,
       total_verification, total_siconfi,
       ROUND(total_verification - total_siconfi, 2)                    AS variation,
       100.0 * (total_verification - total_siconfi) / total_verification AS proportion
FROM verification_function e
LEFT JOIN siconfi s
    ON e.ano = s.ano AND e.sigla_uf = s.sigla_uf
   AND e.id_municipio = s.id_municipio AND e.funcao = s.funcao
WHERE total_siconfi IS NOT NULL AND total_verification IS NOT NULL
  AND total_verification <> 0
ORDER BY variation DESC
", "verification_function_municipality_year.csv")

# ---- payment_municipality_year.csv ----
bq_save("
WITH payment AS (
  SELECT ano, id_municipio,
         SUM(valor_final)           AS total_payment,
         SUM(valor_liquido_recebido) AS total_net_payment
  FROM `basedosdados.world_wb_mides.pagamento`
  WHERE ano >= 2003
  GROUP BY 1, 2
),
siconfi AS (
  SELECT ano, sigla_uf, id_municipio,
         SUM(valor) AS total_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_orcamentarias`
  WHERE sigla_uf IN ('CE','MG','PB','PE','PR','RS','SP')
    AND ano >= 2003
    AND estagio_bd = 'Despesas Pagas'
    AND conta_bd  = 'Despesas Orçamentárias'
  GROUP BY 1, 2, 3
)
SELECT e.ano, sigla_uf, e.id_municipio,
       total_payment, total_net_payment, total_siconfi,
       ROUND(total_payment - total_siconfi, 2)               AS variation,
       100.0 * (total_payment - total_siconfi) / total_payment AS proportion
FROM payment e
FULL OUTER JOIN siconfi s ON e.ano = s.ano AND e.id_municipio = s.id_municipio
WHERE total_siconfi IS NOT NULL AND total_payment IS NOT NULL
  AND total_payment <> 0
", "payment_municipality_year.csv")

# ---- payment_function_municipality_year.csv ----
bq_save("
WITH payment AS (
  SELECT id_empenho_bd, SUM(valor_final) AS total_payment
  FROM `basedosdados.world_wb_mides.pagamento`
  GROUP BY 1
  HAVING id_empenho_bd IS NOT NULL
),
commitment AS (
  SELECT ano, sigla_uf, id_municipio, id_empenho_bd, funcao,
         SUM(valor_final) AS total_commitment
  FROM `basedosdados.world_wb_mides.empenho`
  GROUP BY 1, 2, 3, 4, 5
  HAVING id_empenho_bd IS NOT NULL
),
payment_function AS (
  SELECT ano, sigla_uf, id_municipio, funcao,
         SUM(p.total_payment) AS total_payment
  FROM commitment c
  LEFT JOIN payment p ON c.id_empenho_bd = p.id_empenho_bd
  GROUP BY 1, 2, 3, 4
),
siconfi AS (
  SELECT ano, sigla_uf, id_municipio,
         CASE
           WHEN UPPER(conta_bd) = 'LEGISLATIVA'             THEN '1'
           WHEN UPPER(conta_bd) = 'JUDICIÁRIA'              THEN '2'
           WHEN UPPER(conta_bd) = 'ESSENCIAL À JUSTIÇA'     THEN '3'
           WHEN UPPER(conta_bd) = 'ADMINISTRAÇÃO'           THEN '4'
           WHEN UPPER(conta_bd) = 'DEFESA NACIONAL'         THEN '5'
           WHEN UPPER(conta_bd) = 'SEGURANÇA PÚBLICA'       THEN '6'
           WHEN UPPER(conta_bd) = 'RELAÇÕES EXTERIORES'     THEN '7'
           WHEN UPPER(conta_bd) = 'ASSISTÊNCIA SOCIAL'      THEN '8'
           WHEN UPPER(conta_bd) = 'PREVIDÊNCIA SOCIAL'      THEN '9'
           WHEN UPPER(conta_bd) = 'SAÚDE'                   THEN '10'
           WHEN UPPER(conta_bd) = 'TRABALHO'                THEN '11'
           WHEN UPPER(conta_bd) = 'EDUCAÇÃO'                THEN '12'
           WHEN UPPER(conta_bd) = 'CULTURA'                 THEN '13'
           WHEN UPPER(conta_bd) = 'DIREITOS DA CIDADANIA'   THEN '14'
           WHEN UPPER(conta_bd) = 'URBANISMO'               THEN '15'
           WHEN UPPER(conta_bd) = 'HABITAÇÃO'               THEN '16'
           WHEN UPPER(conta_bd) = 'SANEAMENTO'              THEN '17'
           WHEN UPPER(conta_bd) = 'GESTÃO AMBIENTAL'        THEN '18'
           WHEN UPPER(conta_bd) = 'CIÊNCIA E TECNOLOGIA'    THEN '19'
           WHEN UPPER(conta_bd) = 'AGRICULTURA'             THEN '20'
           WHEN UPPER(conta_bd) = 'ORGANIZAÇÃO AGRÁRIA'     THEN '21'
           WHEN UPPER(conta_bd) = 'INDÚSTRIA'               THEN '22'
           WHEN UPPER(conta_bd) = 'COMÉRCIO E SERVIÇOS'     THEN '23'
           WHEN UPPER(conta_bd) = 'COMUNICAÇÕES'            THEN '24'
           WHEN UPPER(conta_bd) = 'ENERGIA'                 THEN '25'
           WHEN UPPER(conta_bd) = 'TRANSPORTE'              THEN '26'
           WHEN UPPER(conta_bd) = 'DESPORTO E LAZER'        THEN '27'
           WHEN UPPER(conta_bd) = 'ENCARGOS ESPECIAIS'      THEN '28'
           WHEN UPPER(conta_bd) = 'RESERVA DE CONTINGÊNCIA' THEN '99'
         END AS funcao,
         SUM(valor) AS total_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_funcao`
  WHERE ano >= 2003
    AND sigla_uf IN ('CE','MG','PB','PR','RS','SP')   -- PE excluded (no id_empenho_bd)
    AND estagio_bd = 'Despesas Pagas'
  GROUP BY 1, 2, 3, 4
)
SELECT e.ano, e.sigla_uf, e.id_municipio, e.funcao,
       total_payment, total_siconfi,
       ROUND(total_payment - total_siconfi, 2)               AS variation,
       100.0 * (total_payment - total_siconfi) / total_payment AS proportion
FROM payment_function e
LEFT JOIN siconfi s
    ON e.ano = s.ano AND e.sigla_uf = s.sigla_uf
   AND e.id_municipio = s.id_municipio AND e.funcao = s.funcao
WHERE total_siconfi IS NOT NULL AND total_payment IS NOT NULL
  AND total_payment <> 0
ORDER BY variation DESC
", "payment_function_municipality_year.csv")

# ===========================================================================
# 4. SICONFI MUNICIPALITY COUNTS  (total_municipalities.ipynb)
# ===========================================================================

bq_save("
WITH commitment AS (
  SELECT ano, sigla_uf,
         COUNT(DISTINCT id_municipio) AS municipalities_tce
  FROM `basedosdados.world_wb_mides.empenho`
  GROUP BY 1, 2
),
siconfi AS (
  SELECT ano, sigla_uf,
         COUNT(DISTINCT id_municipio) AS municipalities_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_orcamentarias`
  WHERE sigla_uf IN ('CE','MG','PB','PE','PR','RS','SP')
    AND ano >= 2008
    AND estagio_bd = 'Despesas Empenhadas'
    AND conta_bd  = 'Despesas Orçamentárias'
  GROUP BY 1, 2
)
SELECT s.ano AS year_siconfi, e.ano AS year_tce,
       s.sigla_uf AS state_siconfi, e.sigla_uf AS state_tce,
       municipalities_tce, municipalities_siconfi
FROM commitment e
FULL OUTER JOIN siconfi s ON e.ano = s.ano AND e.sigla_uf = s.sigla_uf
", "data_commitment_siconfi.csv")

bq_save("
WITH verification AS (
  SELECT ano, sigla_uf,
         COUNT(DISTINCT id_municipio) AS municipalities_tce
  FROM `basedosdados.world_wb_mides.liquidacao`
  GROUP BY 1, 2
),
siconfi AS (
  SELECT ano, sigla_uf,
         COUNT(DISTINCT id_municipio) AS municipalities_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_orcamentarias`
  WHERE sigla_uf IN ('CE','MG','PB','PE','PR','RS','SP')
    AND ano >= 2008
    AND estagio_bd = 'Despesas Liquidadas'
    AND conta_bd  = 'Despesas Orçamentárias'
  GROUP BY 1, 2
)
SELECT s.ano AS year_siconfi, e.ano AS year_tce,
       s.sigla_uf AS state_siconfi, e.sigla_uf AS state_tce,
       municipalities_tce, municipalities_siconfi
FROM verification e
FULL OUTER JOIN siconfi s ON e.ano = s.ano AND e.sigla_uf = s.sigla_uf
", "data_verification_siconfi.csv")

bq_save("
WITH payment AS (
  SELECT ano, sigla_uf,
         COUNT(DISTINCT id_municipio) AS municipalities_tce
  FROM `basedosdados.world_wb_mides.pagamento`
  GROUP BY 1, 2
),
siconfi AS (
  SELECT ano, sigla_uf,
         COUNT(DISTINCT id_municipio) AS municipalities_siconfi
  FROM `basedosdados.br_me_siconfi.municipio_despesas_orcamentarias`
  WHERE sigla_uf IN ('CE','MG','PB','PE','PR','RS','SP')
    AND ano >= 2008
    AND estagio_bd = 'Despesas Pagas'
    AND conta_bd  = 'Despesas Orçamentárias'
  GROUP BY 1, 2
)
SELECT s.ano AS year_siconfi, e.ano AS year_tce,
       s.sigla_uf AS state_siconfi, e.sigla_uf AS state_tce,
       municipalities_tce, municipalities_siconfi
FROM payment e
FULL OUTER JOIN siconfi s ON e.ano = s.ano AND e.sigla_uf = s.sigla_uf
", "data_payment_siconfi.csv")

# ===========================================================================
# 5. NULL ID CHECKS  (null_ids.ipynb)
# ===========================================================================

bq_save("
SELECT
  ano   AS year,
  sigla_uf AS state,
  COUNT(*)                                                    AS total_observations,
  COUNT(id_empenho_bd)                                        AS total_commitments,
  COUNT(CASE WHEN id_empenho_bd IS NULL THEN 1 END)           AS total_null_commitments,
  SUM(valor_final)                                            AS total_committed,
  SUM(CASE WHEN id_empenho_bd IS NULL THEN valor_final ELSE 0 END) AS total_null_committed
FROM `basedosdados.world_wb_mides.empenho`
WHERE ano IS NOT NULL
GROUP BY 1, 2
", "null_budget_commitment_ids.csv")

bq_save("
SELECT
  ano   AS year,
  sigla_uf AS state,
  COUNT(*)                                                          AS total_observations,
  COUNT(id_liquidacao_bd)                                           AS total_verifications,
  COUNT(CASE WHEN id_liquidacao_bd IS NULL THEN 1 END)              AS total_null_verifications,
  SUM(valor_final)                                                  AS total_verified,
  SUM(CASE WHEN id_liquidacao_bd IS NULL THEN valor_final ELSE 0 END) AS total_null_verified
FROM `basedosdados.world_wb_mides.liquidacao`
WHERE ano IS NOT NULL
GROUP BY 1, 2
", "null_budget_verification_ids.csv")

bq_save("
SELECT
  ano   AS year,
  sigla_uf AS state,
  COUNT(*)                                                        AS total_observations,
  COUNT(id_pagamento_bd)                                          AS total_payments,
  COUNT(CASE WHEN id_pagamento_bd IS NULL THEN 1 END)             AS total_null_payments,
  SUM(valor_final)                                                AS total_paid,
  SUM(CASE WHEN id_pagamento_bd IS NULL THEN valor_final ELSE 0 END) AS total_null_paid
FROM `basedosdados.world_wb_mides.pagamento`
WHERE ano IS NOT NULL
GROUP BY 1, 2
", "null_budget_payment_ids.csv")

bq_save("
SELECT
  ano   AS year,
  sigla_uf AS state,
  COUNT(*)                                                                AS total_observations,
  COUNT(id_licitacao_bd)                                                  AS total_tenders,
  COUNT(CASE WHEN id_licitacao_bd IS NULL THEN 1 END)                     AS total_null_tenders,
  SUM(CASE WHEN valor_corrigido_w IS NULL THEN 0 ELSE valor_corrigido_w END) AS total_procurement_value,
  SUM(CASE WHEN id_licitacao_bd IS NULL THEN CAST(valor_corrigido_w AS FLOAT64) ELSE 0 END)
                                                                          AS total_null_tenders_value
FROM (
  SELECT *,
    CASE
      WHEN valor_corrigido_float < percentile_lower THEN percentile_lower
      WHEN valor_corrigido_float > percentile_upper THEN percentile_upper
      ELSE valor_corrigido_float
    END AS valor_corrigido_w
  FROM (
    SELECT *,
      PERCENTILE_CONT(valor_corrigido_float, 0.01)  OVER (PARTITION BY sigla_uf) AS percentile_lower,
      PERCENTILE_CONT(valor_corrigido_float, 0.999) OVER (PARTITION BY sigla_uf) AS percentile_upper
    FROM (
      SELECT *, SAFE_CAST(valor_corrigido AS FLOAT64) AS valor_corrigido_float
      FROM `basedosdados.world_wb_mides.licitacao`
      WHERE ano IS NOT NULL
    )
  )
)
GROUP BY 1, 2
", "null_tender_ids.csv")

# ===========================================================================
# 6. MISSING MUNICIPALITY COUNTS  (missing_municipalities.ipynb)
# ===========================================================================

bq_save("
SELECT COUNT(DISTINCT id_municipio) AS distinct_municipalities, ano, sigla_uf
FROM `basedosdados.world_wb_mides.licitacao`
GROUP BY ano, sigla_uf
ORDER BY sigla_uf, ano
", "count_mun_lic.csv")

bq_save("
SELECT COUNT(DISTINCT id_municipio) AS distinct_municipalities, ano, sigla_uf
FROM `basedosdados.world_wb_mides.licitacao_item`
GROUP BY ano, sigla_uf
ORDER BY sigla_uf, ano
", "count_mun_lic_item.csv")

bq_save("
SELECT COUNT(DISTINCT id_municipio) AS distinct_municipalities, ano, sigla_uf
FROM `basedosdados.world_wb_mides.licitacao_participante`
GROUP BY ano, sigla_uf
ORDER BY sigla_uf, ano
", "count_mun_lic_part.csv")

bq_save("
SELECT COUNT(DISTINCT id_municipio) AS distinct_municipalities, ano, sigla_uf
FROM `basedosdados.world_wb_mides.empenho`
GROUP BY ano, sigla_uf
ORDER BY sigla_uf, ano
", "count_mun_empenho.csv")

bq_save("
SELECT COUNT(DISTINCT id_municipio) AS distinct_municipalities, ano, sigla_uf
FROM `basedosdados.world_wb_mides.liquidacao`
GROUP BY ano, sigla_uf
ORDER BY sigla_uf, ano
", "count_mun_liq.csv")

bq_save("
SELECT COUNT(DISTINCT id_municipio) AS distinct_municipalities, ano, sigla_uf
FROM `basedosdados.world_wb_mides.pagamento`
GROUP BY ano, sigla_uf
ORDER BY sigla_uf, ano
", "count_mun_pag.csv")

# ===========================================================================
# 7. REFERENCE DATA SOURCED FROM BIGQUERY
# ===========================================================================

# ---- municipios.csv ----
# [STUB] Municipality reference list (from basedosdados or IBGE API).
# See code/archive/descriptive_statistics_municipalities.ipynb.
cat("  [STUB] municipios.csv — see descriptive_statistics_municipalities.ipynb\n")

# ---- population.csv ----
# [STUB] IBGE population by municipality-year (via basedosdados IBGE tables).
# See code/archive/descriptive_statistics_municipalities.ipynb.
cat("  [STUB] population.csv — see descriptive_statistics_municipalities.ipynb\n")

# ===========================================================================
cat("\n==> ingest_bigquery.R complete.\n")
cat("    Files with [STUB] markers were not downloaded.\n")
cat("    Provide those CSVs manually in Data/Intermediate/BigQuery/ or\n")
cat("    recover their queries from code/archive/*.ipynb.\n")
