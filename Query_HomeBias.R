# #Set user's BigQuery billing ID
set_billing_id("projetobd-302617")

in_dir  = "/Users/tscot/Dropbox/MiDES-data-paper-replication/Data/Intermediate/Transparency_Federal_2021"

query <- "
SELECT
    a.*, l.modalidade, l.valor_corrigido, i.sum_item_value,b.data, b.cnpj, b.id_municipio, b.data_inicio_atividade,
    b.sigla_uf, b.cnpj_basico, b.identificador_matriz_filial, s.opcao_simples, s.opcao_mei
FROM (
    SELECT *
    FROM `basedosdados.world_wb_mides.licitacao_participante`
    WHERE id_licitacao_bd IS NOT NULL
  ) a
LEFT JOIN (
    SELECT modalidade, id_licitacao_bd, valor_corrigido
    FROM `basedosdados.world_wb_mides.licitacao`
    WHERE id_licitacao_bd IS NOT NULL
  ) l
ON a.id_licitacao_bd = l.id_licitacao_bd
LEFT JOIN (
    SELECT CAST(FLOOR(SAFE_CAST(documento AS FLOAT64)) AS STRING) AS documento, 
    id_licitacao_bd,
    SUM(
      CASE 
        WHEN sigla_uf = 'PR' THEN quantidade_proposta*valor_vencedor
        ELSE COALESCE(valor_total,0)
      END)
    AS sum_item_value
    FROM `basedosdados.world_wb_mides.licitacao_item`
    WHERE id_licitacao_bd IS NOT NULL
    GROUP BY documento, id_licitacao_bd
  ) i
ON a.id_licitacao_bd = i.id_licitacao_bd AND
   a.documento = i.documento 
LEFT JOIN (
    SELECT
        CAST(cnpj AS STRING) AS cnpj,
        cnpj_basico,
        id_municipio,
        sigla_uf,
        identificador_matriz_filial,
        data_inicio_atividade,
        MAX(data) AS data
    FROM
        `basedosdados.br_me_cnpj.estabelecimentos`
    GROUP BY
        cnpj,
        cnpj_basico,
        id_municipio,
        sigla_uf,
        data_inicio_atividade,
        identificador_matriz_filial
) b ON CAST(a.documento AS STRING) = b.cnpj
LEFT JOIN
    `basedosdados.br_me_cnpj.simples` s ON b.cnpj_basico = s.cnpj_basico
WHERE
    a.tipo = '1'
"


items_query = read_sql(query)

items_query = setDT(items_query)
fwrite(items_query, paste0(in_dir, '/mides_2021_items_alternative_price.csv'))
