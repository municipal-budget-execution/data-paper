WITH pagamento_mg AS (
  SELECT 
    SAFE_CAST (p.ano AS INT64) AS ano,
    SAFE_CAST (p.mes AS INT64) AS mes,
    SAFE_CAST (p.data AS DATE) AS data,
    SAFE_CAST (p.sigla_uf AS STRING) AS sigla_uf,
    SAFE_CAST (p.id_municipio AS STRING) AS id_municipio,
    SAFE_CAST (p.orgao AS STRING) AS orgao,
    SAFE_CAST (p.id_unidade_gestora AS STRING) AS id_unidade_gestora,
    CASE 
      WHEN p.id_empenho != '-1' THEN CONCAT(p.id_empenho, l.orgao, l.id_municipio, (RIGHT(p.ano,2)))
      WHEN p.id_empenho = '-1'  THEN CONCAT(id_empenho_origem, r.orgao, r.id_municipio, (RIGHT(p.ano,2)))
    END AS id_empenho_bd,
    CASE 
      WHEN p.id_empenho = '-1' THEN REPLACE (p.id_empenho, '-1', id_empenho_origem) END AS id_empenho,
    SAFE_CAST (numero_empenho AS STRING) AS numero_empenho,
    CASE 
      WHEN p.id_liquidacao != '-1' THEN CONCAT(p.id_liquidacao, l.orgao, l.id_municipio, (RIGHT(p.ano,2)))
      WHEN p.id_liquidacao = '-1'  THEN CONCAT(l.id_liquidacao, r.orgao, r.id_municipio, (RIGHT(p.ano,2)))
    END AS id_liquidacao_bd,
    SAFE_CAST (p.id_liquidacao AS STRING) AS id_liquidacao,
    SAFE_CAST (p.numero_liquidacao AS STRING) AS numero_liquidacao,
    SAFE_CAST (CONCAT(id_pagamento, p.orgao, p.id_municipio, (RIGHT(p.ano,2))) AS STRING) AS id_pagamento_bd,
    SAFE_CAST (id_pagamento AS STRING) AS id_pagamento,
    SAFE_CAST (p.numero_pagamento AS STRING) AS numero,
    SAFE_CAST (nome_credor AS STRING) AS nome_credor,
    SAFE_CAST (REPLACE(REPLACE (documento_credor, '.', ''), '-','') AS STRING) AS documento_credor,
    CASE WHEN p.id_rsp != '-1' THEN 1 ELSE 0 END AS indicador_restos_pagar,
    SAFE_CAST (fonte AS STRING) AS fonte,
    SAFE_CAST (valor_pagamento_original AS FLOAT64) AS valor_inicial,
    SAFE_CAST (valor_anulado AS FLOAT64) AS valor_anulacao,
    NULL AS valor_ajuste,
    SAFE_CAST (valor_pagamento AS FLOAT64) AS valor_final,
    NULL AS valor_liquido_recebido,
  FROM basedosdados-dev.mundo_bm_financas_publicas_staging.pagamento_mg AS p
  LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_rsp_mg AS r ON p.id_rsp=r.id_rsp
  LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_liquidacao_mg AS l ON l.id_rsp=r.id_rsp
  WHERE id_empenho_origem != '-1'
),
  
  pagamento_sp AS (
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
      SAFE_CAST (NULL AS STRING) AS numero_liquidacao,
      SAFE_CAST (CONCAT(LEFT(nr_empenho, LENGTH(nr_empenho) - 5), cd_orgao, id_municipio, (RIGHT(ano_exercicio,2))) AS STRING) AS id_pagamento_bd,
      SAFE_CAST (NULL AS STRING) AS id_pagamento,
      SAFE_CAST (NULL AS STRING) AS numero,
      SAFE_CAST (ds_despesa AS STRING) AS nome_credor,
      SAFE_CAST (identificador_despesa AS STRING) AS documento_credor,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      CASE 
        WHEN ds_fonte_recurso = 'TESOURO' THEN '1'
        WHEN ds_fonte_recurso = 'TRANSFERÊNCIAS E CONVÊNIOS ESTADUAIS-VINCULADOS' THEN '2'
        WHEN ds_fonte_recurso = 'RECURSOS PRÓPRIOS DE FUNDOS ESPECIAIS DE DESPESA-VINCULADOS' THEN '3'
        WHEN ds_fonte_recurso = 'RECURSOS PRÓPRIOS DA ADMINISTRAÇÃO INDIRETA' THEN '4'
        WHEN ds_fonte_recurso = 'TRANSFERÊNCIAS E CONVÊNIOS FEDERAIS-VINCULADOS' THEN '5'
        WHEN ds_fonte_recurso = 'OUTRAS FONTES DE RECURSOS' THEN '6'
        WHEN ds_fonte_recurso = 'OPERAÇÕES DE CRÉDITO' THEN '7'
        WHEN ds_fonte_recurso = 'EMENDAS PARLAMENTARES INDIVIDUAIS' THEN '8'
        WHEN ds_fonte_recurso = 'TESOURO - EXERCICIOS ANTERIORES' THEN '91'
        WHEN ds_fonte_recurso = 'TRANSFERÊNCIAS E CONVÊNIOS ESTADUAIS-VINCULADOS - EXERCICIOS ANTERIORES' THEN '92'
        WHEN ds_fonte_recurso = 'RECURSOS PRÓPRIOS DE FUNDOS ESPECIAIS DE DESPESA-VINCULADOS - EXERCICIOS ANTERIORES' THEN '93'
        WHEN ds_fonte_recurso = 'RECURSOS PRÓPRIOS DA ADMINISTRAÇÃO INDIRETA - EXERCICIOS ANTERIORES' THEN '94'
        WHEN ds_fonte_recurso = 'TRANSFERÊNCIAS E CONVÊNIOS FEDERAIS-VINCULADOS - EXERCICIOS ANTERIORES' THEN '95'
        WHEN ds_fonte_recurso = 'OUTRAS FONTES DE RECURSOS - EXERCICIOS ANTERIORES' THEN '96'
        WHEN ds_fonte_recurso = 'OPERAÇÕES DE CRÉDITO - EXERCICIOS ANTERIORES' THEN '97'
        ELSE NULL  
      END AS fonte,
      SAFE_CAST (REPLACE(vl_despesa, ',', '.') AS FLOAT64) AS valor_inicial,
      NULL AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (REPLACE(vl_despesa, ',', '.') AS FLOAT64) AS valor_final,
      NULL AS valor_liquido_recebido,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_despesa_sp
    INNER JOIN basedosdados.br_bd_diretorios_brasil.municipio ON ds_municipio = nome
    WHERE tp_despesa = 'Valor Pago'
),

  pagamento_pr AS (
    SELECT
      SAFE_CAST (nrAnoPagamento AS INT64) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE (dtOperacao)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(dtOperacao)) AS DATE) AS data,
      sigla_uf, 
      id_municipio,
      SAFE_CAST (cdOrgao AS STRING) AS orgao,
      SAFE_CAST (cdUnidade AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(p.idEmpenho, cdOrgao, id_municipio, (RIGHT(nrAnoEmpenho,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (p.idEmpenho AS STRING) AS id_empenho,
      SAFE_CAST (nrEmpenho AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(idLiquidacao, cdOrgao, id_municipio, (RIGHT(nrAnoEmpenho,2))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (idLiquidacao AS STRING) AS id_liquidacao,
      SAFE_CAST (NULL AS STRING) AS numero_liquidacao,
      SAFE_CAST (CONCAT(idPagamento, cdOrgao, id_municipio, (RIGHT(nrAnoEmpenho,2))) AS STRING) AS id_pagamento_bd,
      SAFE_CAST (idPagamento AS STRING) AS id_pagamento,
      SAFE_CAST (nrPagamento AS STRING) AS numero,
      SAFE_CAST (nmCredor AS STRING) AS nome_credor,
      SAFE_CAST (REPLACE (REPLACE (REPLACE (REPLACE (REPLACE (nrDocCredor, '.', ''), '-',''),'CNPJ - PESSOA JURÍDICA - ',''),'PESSOA FÍSICA - ', '*****'),'IDENTIFICAÇÃO ESPECIAL - SEM CPF/CNPJ - ','') AS STRING) AS documento_credor,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (cdFonteReceita AS STRING) AS fonte,
      SAFE_CAST (vlOperacao AS FLOAT64) AS valor_inicial,
      SAFE_CAST (nrAnoLiquidacao AS FLOAT64) AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (p.cdIBGE AS FLOAT64) AS valor_final,
      NULL AS valor_liquido_recebido,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_pagamento_pr p
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pr e ON p.idEmpenho = e.idEmpenho
    INNER JOIN basedosdados.br_bd_diretorios_brasil.municipio ON e.cdIBGE = id_municipio_6
),

  pagamento_pe AS (
    SELECT
      SAFE_CAST (p.ANOREFERENCIA AS INT64) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE(DATA)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(DATA)) AS DATE) AS data,
      SAFE_CAST (UNIDADEFEDERATIVA AS STRING) AS sigla_uf, 
      SAFE_CAST (CODIGOIBGE AS STRING) AS id_municipio,
      SAFE_CAST (NULL AS STRING) orgao,
      SAFE_CAST (ID_UNIDADEGESTORA AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(TRIM(IDEMPENHO), ID_UNIDADEGESTORA, CODIGOIBGE, (RIGHT(p.ANOREFERENCIA,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (TRIM(IDEMPENHO) AS STRING) AS id_empenho,
      SAFE_CAST (p.NUMEROEMPENHO AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(TRIM(IDEMPENHO), ID_UNIDADEGESTORA, CODIGOIBGE, (RIGHT(p.ANOREFERENCIA,2))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_liquidacao,
      SAFE_CAST (NULL AS STRING) AS numero_liquidacao,
      SAFE_CAST (CONCAT(TRIM(IDEMPENHO), ID_UNIDADEGESTORA, CODIGOIBGE, (RIGHT(p.ANOREFERENCIA,2))) AS STRING) AS id_pagamento_bd,
      SAFE_CAST (NULL AS STRING) AS id_pagamento,
      SAFE_CAST (NULL AS STRING) AS numero,
      SAFE_CAST (FORNECEDOR AS STRING) AS nome_credor,
      SAFE_CAST (REPLACE (REPLACE (CPF_CNPJ, '.',''), '-','') AS STRING) AS documento_credor,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (NULL AS STRING) AS fonte,
      NULL AS valor_inicial,
      NULL AS valor_anulacao,
      ROUND(CAST (VALORPAGO AS FLOAT64) - IFNULL(CAST (VALOR AS FLOAT64),0),2) AS valor_ajuste,
      SAFE_CAST (VALORPAGO AS FLOAT64) AS valor_final,
      SAFE_CAST (VALOR AS FLOAT64) AS valor_liquido_recebido,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_pagamento_pe p
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pe e ON p.IDEMPENHO = RTRIM(e.ID_EMPENHO) AND p.NUMEROEMPENHO = e.NUMEROEMPENHO AND p.ID_UNIDADE_GESTORA = e.ID_UNIDADE_GESTORA
    INNER JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_municipio_pe m ON p.ID_UNIDADE_GESTORA = ID_UNIDADEGESTORA
    WHERE TIPO = 'Pagamento'

),

  pagamento_rs AS (
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
    SAFE_CAST (nr_liquidacao AS STRING) AS numero_liquidacao,
    SAFE_CAST(CONCAT(nr_pagamento, c.cd_orgao, m.id_municipio, (RIGHT(ano_operacao,2))) AS STRING) AS id_pagamento_bd,
    SAFE_CAST (NULL AS STRING) AS id_pagamento,
    SAFE_CAST (nr_pagamento AS STRING) AS numero,
    SAFE_CAST (nm_credor AS STRING) AS nome_credor,
    SAFE_CAST (cnpj_cpf AS STRING) AS documento_credor,
    SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
    SAFE_CAST (NULL AS STRING) AS fonte,
    SAFE_CAST(NULL AS FLOAT64) AS valor_inicial,
    SAFE_CAST(NULL AS FLOAT64) AS valor_anulacao,
    SAFE_CAST(NULL AS FLOAT64) AS valor_ajuste,
    SAFE_CAST(vl_pagamento AS FLOAT64) AS valor_final,
    SAFE_CAST (NULL AS FLOAT64) AS valor_liquido_recebido
  FROM `basedosdados-dev.mundo_bm_financas_publicas_staging.raw_despesa_rs` AS c
  LEFT JOIN `basedosdados-dev.mundo_bm_financas_publicas_staging.aux_orgao_rs` AS a ON c.cd_orgao = a.cd_orgao
  LEFT JOIN `basedosdados.br_bd_diretorios_brasil.municipio` m ON m.id_municipio = a.id_municipio
  WHERE tipo_operacao = 'P'
  GROUP BY 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20, 21, 22, 23, 24
),
  pagamento_pb AS (
    SELECT
      SAFE_CAST (p.dt_Ano AS INT64) AS ano,
      SAFE_CAST(SUBSTRING(TRIM(dt_empenho),-7,2) AS INT64) AS mes,
      SAFE_CAST (CONCAT(SUBSTRING(TRIM(dt_empenho),-4),'-',SUBSTRING(TRIM(dt_empenho),-7,2),'-',SUBSTRING(TRIM(dt_empenho),1,2))AS DATE) AS data,
      m.sigla_uf, 
      m.id_municipio,
      SAFE_CAST (SUBSTRING(TRIM(e.cd_ugestora, '0'),1,1) AS STRING) AS  orgao,
      SAFE_CAST (e.cd_ugestora AS STRING) AS id_unidade_gestora, -- colocar aqui unidade_orcamentaria
      SAFE_CAST (CONCAT(p.nu_Empenho, e.cd_ugestora, m.id_municipio, (RIGHT(p.dt_Ano,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS id_empenho,
      SAFE_CAST (p.nu_Empenho AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(p.nu_Parcela, p.cd_ugestora, id_municipio, (RIGHT(p.dt_Ano,2))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_liquidacao,
      SAFE_CAST (NULL AS STRING) AS numero_liquidacao,
      SAFE_CAST (CONCAT(p.nu_Empenho, (SAFE_CAST (nu_Parcela AS INT64)), e.cd_ugestora, id_municipio, (RIGHT(p.dt_Ano,2))) AS STRING) AS id_pagamento_bd,
      SAFE_CAST (NULL AS STRING) AS id_pagamento,
      SAFE_CAST (nu_Parcela AS STRING) AS numero,
      SAFE_CAST (no_Credor AS STRING) AS nome_credor,
      SAFE_CAST (REPLACE (REPLACE (cd_credor, '.', ''), '-','') AS STRING) AS documento_credor,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (tp_FonteRecursos AS STRING) AS fonte,
      SAFE_CAST (vl_Pagamento AS FLOAT64) AS valor_inicial,
      SAFE_CAST (NULL AS FLOAT64) AS valor_anulacao,
      SAFE_CAST (vl_Retencao AS FLOAT64) AS valor_ajuste,
      SAFE_CAST (vl_Pagamento AS FLOAT64) - SAFE_CAST (vl_Retencao AS FLOAT64) AS valor_final,
      NULL AS valor_liquido_recebido,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_pagamento_pb p
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pb e ON p.nu_Empenho = e.nu_Empenho
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.aux_municipio_pb m ON e.cd_ugestora = m.id_unidade_gestora
),
  pagamento_ce AS (
    SELECT
      (SAFE_CAST(EXTRACT(YEAR FROM DATE(data_nota_pagamento)) AS INT64)) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE(data_nota_pagamento)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(data_nota_pagamento)) AS DATE) AS data,
      'CE' AS sigla_uf, 
      SAFE_CAST (e.geoibgeId AS STRING) AS id_municipio,
      SAFE_CAST (p.codigo_orgao AS STRING) orgao,
      SAFE_CAST (p.codigo_unidade AS STRING) AS id_unidade_gestora,
      SAFE_CAST (CONCAT(p.numero_empenho, p.codigo_unidade, e.geoibgeId, (SUBSTRING(p.data_referencia,1,4))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS id_empenho,
      SAFE_CAST (p.numero_empenho AS STRING) AS numero_empenho,
      SAFE_CAST (CONCAT(p.numero_empenho, p.codigo_unidade, e.geoibgeId, (SUBSTRING(p.data_referencia,1,4))) AS STRING) AS id_liquidacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_liquidacao,
      SAFE_CAST (NULL AS STRING) AS numero_liquidacao,
      SAFE_CAST (CONCAT(numero_nota_pagamento,p.codigo_unidade, e.geoibgeId, (SUBSTRING(p.data_referencia,1,4))) AS STRING) AS id_pagamento_bd,
      SAFE_CAST (NULL AS STRING) AS id_pagamento,
      SAFE_CAST (numero_nota_pagamento AS STRING) AS numero,
      SAFE_CAST (nome_negociante AS STRING) AS nome_credor,
      SAFE_CAST (REPLACE (REPLACE (numero_documento_negociante, '.',''), '-','') AS STRING) AS documento_credor,
      SAFE_CAST (NULL AS INT64) AS indicador_restos_pagar,
      SAFE_CAST (codigo_fonte_ AS STRING) AS fonte,
      SAFE_CAST (valor_empenhado_a_pagar AS FLOAT64) AS valor_inicial,
      NULL AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (valor_nota_pagamento AS FLOAT64) AS valor_final,
      NULL AS valor_liquido_recebido,
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_pagamento_ce p
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_ce e ON p.numero_empenho=e.numero_empenho
)

SELECT 
    *
FROM pagamento_mg
UNION ALL (SELECT * FROM pagamento_sp)
UNION ALL (SELECT * FROM pagamento_pr)
UNION ALL (SELECT * FROM pagamento_pe)
UNION ALL (SELECT * FROM pagamento_rs)
UNION ALL (SELECT * FROM pagamento_pb)
UNION ALL (SELECT * FROM pagamento_ce)