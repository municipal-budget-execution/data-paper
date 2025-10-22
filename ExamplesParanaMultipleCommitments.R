SELECT * FROM `basedosdados.world_wb_mides.empenho`
WHERE id_empenho IN ('67007547', '78283291', '74557531', '78283087')

SELECT * FROM `basedosdados-dev.world_wb_mides.relacionamentos`
WHERE id_licitacao = '1390151'

SELECT * FROM `basedosdados.world_wb_mides.licitacao`
WHERE sigla_uf = "PR" AND id_municipio = '4127908' AND id_licitacao = '1390151'



WITH procurement AS (
  SELECT
  p.ano
  ,p.sigla_uf
  ,p.id_municipio
  ,p.valor_orcamento
  ,p.valor_corrigido
  ,p.id_licitacao
  FROM basedosdados.world_wb_mides.licitacao p
  WHERE sigla_uf = "PR"
  LIMIT 1000
)

,relacionamento AS (
  SELECT * FROM `basedosdados-dev.world_wb_mides.relacionamentos`  r
)






,empenho AS (
  SELECT 
  e.ano
  ,e.sigla_uf
  ,e.id_municipio
  ,e.id_empenho
  ,e.valor_final
  ,e.valor_inicial
  ,e.descricao FROM `basedosdados.world_wb_mides.empenho` e
  WHERE sigla_uf = 'PR'
)

SELECT
p.ano
,p.sigla_uf
,p.id_municipio
,p.valor_orcamento
,p.id_licitacao
,p.valor_corrigido
,r.id_empenho
,e.valor_final
,e.valor_inicial
,e.descricao
FROM procurement p
LEFT JOIN relacionamento r ON p.ano = r.ano AND p.sigla_uf = r.sigla_uf AND p.id_municipio = r.id_municipio AND p.id_licitacao =  r.id_licitacao
LEFT JOIN empenho e ON p.ano = e.ano AND p.sigla_uf = e.sigla_uf AND p.id_municipio = e.id_municipio AND r.id_empenho =  e.id_empenho
