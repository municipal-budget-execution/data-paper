WITH liquidacao_mg AS (
  SELECT 
    SAFE_CAST (ano AS INT64) AS ano,
    SAFE_CAST (mes AS INT64) AS mes,
    SAFE_CAST (data AS DATE) AS data,
    SAFE_CAST (sigla_uf AS STRING) AS sigla_uf,
    SAFE_CAST (l.id_municipio AS STRING) AS id_municipio,
    SAFE_CAST (l.orgao AS STRING) AS orgao,
    SAFE_CAST (l.id_unidade_gestora AS STRING) AS id_unidade_gestora,
    CASE 
      WHEN id_empenho != '-1' THEN CONCAT(id_empenho, l.orgao, l.id_municipio, (RIGHT(ano,2)))
      WHEN id_empenho = '-1'  THEN CONCAT(id_empenho_origem, r.orgao, r.id_municipio, (RIGHT(ano,2)))
      END AS id_empenho_bd,
    CASE 
      WHEN id_empenho = '-1' THEN REPLACE (id_empenho, '-1', id_empenho_origem) END AS id_empenho,
    SAFE_CAST (numero_empenho AS STRING) AS numero_empenho,
    SAFE_CAST (CONCAT(id_liquidacao, l.orgao, l.id_municipio, (RIGHT(ano,2))) AS STRING) AS id_liquidacao_bd,
    SAFE_CAST (id_liquidacao AS STRING) AS id_liquidacao,
    SAFE_CAST (numero_liquidacao AS STRING) AS numero,
    SAFE_CAST (nome_responsavel AS STRING) AS nome_responsavel,
    SAFE_CAST (documento_responsavel AS STRING) AS documento_responsavel,
    CASE WHEN l.id_rsp != '-1' THEN 1 ELSE 0 END AS indicador_restos_pagar,
    SAFE_CAST (valor_liquidacao_original AS FLOAT64) AS valor_inicial,
    SAFE_CAST (valor_anulado AS FLOAT64) AS valor_anulacao,
    NULL AS valor_ajuste,
    SAFE_CAST (valor_liquidacao_original AS FLOAT64) - SAFE_CAST (valor_anulado AS FLOAT64) AS valor_final
  FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_liquidacao_mg AS l
  LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_rsp_mg AS r ON l.id_rsp=r.id_rsp
  LEFT JOIN basedosdados-dev.br_bd_diretorios_brasil.municipio m ON m.id_municipio = l.id_municipio
  WHERE id_empenho_origem != '-1'
),
  
  liquidacao_sp AS (
    SELECT 
      SAFE_CAST (ano_exercicio AS INT64) AS ano,
      SAFE_CAST (mes_referencia AS INT64) AS mes,
      SAFE_CAST (CONCAT(SUBSTRING(dt_emissao_despesa,-4),'-',SUBSTRING(dt_emissao_despesa,-7,2),'-',SUBSTRING(dt_emissao_despesa,1,2))AS DATE) AS data,
      sigla_uf, 
      id_municipio,
      SAFE_CAST (cd_orgao AS STRING) AS orgao,
      SAFE_CAST (NULL AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(LEFT(nr_empenho, LENGTH(nr_empenho) - 5), cd_orgao, id_municipio, (RIGHT(ano_exercicio,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS id_empenho,      
      SAFE_CAST (nr_empenho AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(LEFT(nr_empenho, LENGTH(nr_empenho) - 5), cd_orgao, id_municipio, (RIGHT(ano_exercicio,2))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_liquidacao,
      SAFE_CAST (NULL AS STRING) AS numero,
      SAFE_CAST (NULL AS STRING) AS nome_responsavel,
      SAFE_CAST (NULL AS STRING) AS documento_responsavel,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (REPLACE(vl_despesa, ',', '.') AS FLOAT64) AS valor_inicial,
      NULL AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (REPLACE(vl_despesa, ',', '.') AS FLOAT64) AS valor_final
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_despesa_sp
    INNER JOIN basedosdados.br_bd_diretorios_brasil.municipio ON ds_municipio = nome
    WHERE tp_despesa = 'Valor Liquidado'
),

  liquidacao_pr AS (
    SELECT
      SAFE_CAST (nrAnoLiquidacao AS INT64) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE (dtLiquidacao)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(dtLiquidacao)) AS DATE) AS data,
      sigla_uf, 
      id_municipio,
      SAFE_CAST (cdOrgao AS STRING) AS orgao,
      SAFE_CAST (cdUnidade AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(l.idEmpenho, cdOrgao, id_municipio, (RIGHT(nrAnoEmpenho,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (l.idEmpenho AS STRING) AS id_empenho,
      SAFE_CAST (nrEmpenho AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(l.idLiquidacao, cdOrgao, id_municipio, (RIGHT(nrAnoEmpenho,2))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (idLiquidacao AS STRING) AS id_liquidacao,
      SAFE_CAST (nrLiquidacao AS STRING) AS numero,
      SAFE_CAST (nmLiquidante AS STRING) AS nome_responsavel,
      SAFE_CAST (nrDocLiquidante AS STRING) AS documento_responsavel,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (vlLiquidacaoBruto AS FLOAT64) AS valor_inicial,
      SAFE_CAST (vlLiquidacaoEstornado AS FLOAT64) AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (vlLiquidacaoLiquido AS FLOAT64) AS valor_final,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_liquidacao_pr l
    INNER JOIN basedosdados.br_bd_diretorios_brasil.municipio ON cdIBGE = id_municipio_6
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pr e ON l.idEmpenho = e.idEmpenho
),

  liquidacao_pe AS (
    SELECT
      SAFE_CAST (l.ANOREFERENCIA AS INT64) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE(DATA)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(DATA)) AS DATE) AS data,
      SAFE_CAST (UNIDADEFEDERATIVA AS STRING) AS sigla_uf, 
      SAFE_CAST (CODIGOIBGE AS STRING) AS id_municipio,
      SAFE_CAST (NULL AS STRING) orgao,
      SAFE_CAST (ID_UNIDADEGESTORA AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(TRIM(IDEMPENHO), ID_UNIDADEGESTORA, CODIGOIBGE, (RIGHT(l.ANOREFERENCIA,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (TRIM(IDEMPENHO) AS STRING) AS id_empenho,
      SAFE_CAST (l.NUMEROEMPENHO AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(TRIM(IDEMPENHO), ID_UNIDADEGESTORA, CODIGOIBGE, (RIGHT(l.ANOREFERENCIA,2))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_liquidacao,
      SAFE_CAST (NULL AS STRING) AS numero,
      SAFE_CAST (NULL AS STRING) AS nome_responsavel,
      SAFE_CAST (NULL AS STRING) AS documento_responsavel,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (VALOR AS FLOAT64) AS valor_inicial,
      NULL AS valor_anulacao,
      ROUND(CAST (VALORLIQUIDADO AS FLOAT64) - IFNULL(CAST (VALOR AS FLOAT64),0),2) AS valor_ajuste,
      SAFE_CAST (VALORLIQUIDADO AS FLOAT64) AS valor_final,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_liquidacao_pe l
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pe e ON l.IDEMPENHO = RTRIM(e.ID_EMPENHO) AND l.NUMEROEMPENHO = e.NUMEROEMPENHO AND l.ID_UNIDADE_GESTORA = e.ID_UNIDADE_GESTORA
    INNER JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_municipio_pe m ON l.ID_UNIDADE_GESTORA = ID_UNIDADEGESTORA
    WHERE TIPO = 'Liquidação'
),

  liquidacao_rs AS (
    SELECT
        MIN(SAFE_CAST(ano_operacao AS INT64)) AS ano,
        SAFE_CAST(EXTRACT(MONTH FROM DATE(dt_operacao)) AS INT64) AS mes,
        SAFE_CAST(dt_operacao AS DATE) AS data,
        m.sigla_uf AS sigla_uf,
        SAFE_CAST(a.id_municipio AS STRING) AS id_municipio,
        SAFE_CAST(c.cd_orgao AS STRING) AS orgao,
        SAFE_CAST(cd_orgao_orcamentario AS STRING) AS id_unidade_gestora,
        SAFE_CAST(CONCAT(nr_empenho, c.cd_orgao, m.id_municipio, (RIGHT(ano_operacao,2))) AS STRING) AS id_empenho_bd,
        SAFE_CAST(NULL AS STRING) AS id_empenho,
        SAFE_CAST(nr_empenho AS STRING) AS numero_empenho,
        SAFE_CAST(CONCAT(nr_liquidacao, c.cd_orgao, m.id_municipio, (RIGHT(ano_operacao,2))) AS STRING) AS id_liquidacao_bd,
        SAFE_CAST (NULL AS STRING) AS id_liquidacao,
        SAFE_CAST (nr_liquidacao AS STRING) AS numero,
        SAFE_CAST (NULL AS STRING) AS nome_responsavel,
        SAFE_CAST (NULL AS STRING) AS documento_responsavel,
        SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
        SAFE_CAST(NULL AS FLOAT64) AS valor_inicial,
        SAFE_CAST(NULL AS FLOAT64) AS valor_anulacao,
        SAFE_CAST(NULL AS FLOAT64) AS valor_ajuste,
        SAFE_CAST(vl_liquidacao AS FLOAT64) AS valor_final
      FROM `basedosdados-dev.mundo_bm_financas_publicas_staging.raw_despesa_rs` AS c
      LEFT JOIN `basedosdados-dev.mundo_bm_financas_publicas_staging.aux_orgao_rs` AS a ON c.cd_orgao = a.cd_orgao
      LEFT JOIN `basedosdados.br_bd_diretorios_brasil.municipio` m ON m.id_municipio = a.id_municipio
      WHERE tipo_operacao = 'L'
      GROUP BY 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
),

  liquidacao_pb AS (
    SELECT
      SAFE_CAST (dt_Ano AS INT64) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE (dt_Liquidacao)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(dt_Liquidacao)) AS DATE) AS data,
      sigla_uf, 
      id_municipio,
      SAFE_CAST (NULL AS STRING) AS  orgao,
      SAFE_CAST (cd_ugestora AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(l.nu_Empenho, cd_ugestora, id_municipio, (RIGHT(dt_Ano,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS  id_empenho,
      SAFE_CAST (nu_Empenho AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(l.nu_Liquidacao, cd_ugestora, id_municipio, (RIGHT(dt_Ano,2))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_liquidacao,
      SAFE_CAST (nu_Liquidacao AS STRING) AS numero,
      SAFE_CAST (NULL AS STRING) AS nome_responsavel,
      SAFE_CAST (NULL AS STRING) AS documento_responsavel,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (vl_Liquidacao AS FLOAT64) AS valor_inicial,
      NULL AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (vl_Liquidacao AS FLOAT64) AS valor_final,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_liquidacao_pb l
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.aux_municipio_pb m ON l.cd_ugestora = m.id_unidade_gestora
),

  liquidacao_ce AS (
    SELECT
      (SAFE_CAST(EXTRACT(YEAR FROM DATE (data_liquidacao)) AS INT64)) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE (data_liquidacao)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(data_liquidacao)) AS DATE) AS data,
      sigla_uf, 
      SAFE_CAST (geoibgeId AS STRING) AS id_municipio,
      SAFE_CAST (codigo_orgao AS STRING) AS  orgao,
      SAFE_CAST (codigo_unidade AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(numero_empenho, codigo_unidade, geoibgeId, (SUBSTRING(exercicio_orcamento,3,4))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS  id_empenho,
      SAFE_CAST (numero_empenho AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(numero_sub_empenho_liquidacao, codigo_unidade, geoibgeId, (SUBSTRING(exercicio_orcamento,3,4))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_liquidacao,
      SAFE_CAST (numero_sub_empenho_liquidacao AS STRING) AS numero,
      SAFE_CAST (nome_responsavel_liquidacao AS STRING) AS nome_responsavel,
      SAFE_CAST (cpf_responsavel_liquidacao_ AS STRING) AS documento_responsavel,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (valor_liquidado AS FLOAT64) AS valor_inicial,
      NULL AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (valor_liquidado AS FLOAT64) AS valor_final,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_liquidacao_ce
)

SELECT 
    *
FROM liquidacao_mg
UNION ALL (SELECT * FROM liquidacao_sp)
UNION ALL (SELECT * FROM liquidacao_pr)
UNION ALL (SELECT * FROM liquidacao_pe)
UNION ALL (SELECT * FROM liquidacao_rs)
UNION ALL (SELECT * FROM liquidacao_pb)
UNION ALL (SELECT * FROM liquidacao_ce)