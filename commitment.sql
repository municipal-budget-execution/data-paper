CREATE OR REPLACE TABLE mundo_bm_financas_publicas_staging.empenho (
  ano                    INT64,
  mes                    INT64,
  data                   DATE,
  sigla_uf               STRING,
  id_municipio           STRING,
  orgao                  STRING,
  id_unidade_gestora     STRING,
  id_licitacao_bd        STRING,
  id_licitacao           STRING,
  modalidade_licitacao   STRING,
  id_empenho_bd          STRING,
  id_empenho             STRING,
  numero                 STRING,
  descricao              STRING,
  modalidade             STRING,
  funcao                 STRING,
  subfuncao              STRING,
  programa               STRING,
  acao                   STRING,
  elemento_despesa       STRING,
  valor_inicial          FLOAT64,
  valor_reforco          FLOAT64,
  valor_anulacao         FLOAT64,
  valor_ajuste           FLOAT64,
  valor_final            FLOAT64
) CLUSTER BY ano, mes, sigla_uf AS (

WITH empenho_mg AS (
  SELECT
    SAFE_CAST (ano AS INT64) AS ano,
    SAFE_CAST (mes AS INT64) AS mes,
    SAFE_CAST (data AS DATE) AS data,
    SAFE_CAST (sigla_uf AS STRING) AS sigla_uf,
    SAFE_CAST (id_municipio AS STRING) AS id_municipio,
    SAFE_CAST (TRIM(orgao, '0') AS STRING) AS  orgao,
    SAFE_CAST (id_unidade_gestora AS STRING) AS id_unidade_gestora,
    SAFE_CAST (NULL AS STRING) AS id_licitacao_bd,
    SAFE_CAST (id_licitacao AS STRING) AS id_licitacao,
    SAFE_CAST (NULL AS STRING) AS modalidade_licitacao,
    SAFE_CAST (CONCAT(id_empenho, orgao, id_municipio, (RIGHT(ano,2))) AS STRING) AS id_empenho_bd,
    SAFE_CAST (id_empenho AS STRING) AS id_empenho,
    SAFE_CAST (numero_empenho AS STRING) AS numero,
    SAFE_CAST (descricao AS STRING) AS descricao,
    SAFE_CAST (modalidade AS STRING) AS modalidade,
    SAFE_CAST (CAST(funcao AS INT64) AS STRING) AS funcao,
    SAFE_CAST (subfuncao AS STRING) AS subfuncao,
    SAFE_CAST (programa AS STRING) AS programa,
    SAFE_CAST (acao AS STRING) AS acao,
    SAFE_CAST (elemento_despesa AS STRING) AS elemento_despesa,
    SAFE_CAST (valor_empenho_original AS FLOAT64) AS valor_original,
    SAFE_CAST (valor_reforco AS FLOAT64) AS valor_reforco,
    SAFE_CAST (valor_anulacao AS FLOAT64) AS valor_anulacao,
    NULL AS valor_ajuste,
    SAFE_CAST (valor_empenho AS FLOAT64) AS valor_final
  FROM basedosdados-dev.mundo_bm_financas_publicas_staging.empenho_mg
),
 
  empenho_sp AS (
    SELECT
      SAFE_CAST (ano_exercicio AS INT64) AS ano,
      SAFE_CAST (mes_referencia AS INT64) AS mes,
      SAFE_CAST (CONCAT(SUBSTRING(dt_emissao_despesa,-4),'-',SUBSTRING(dt_emissao_despesa,-7,2),'-',SUBSTRING(dt_emissao_despesa,1,2))AS DATE) AS data,
      sigla_uf, 
      id_municipio,
      SAFE_CAST (cd_orgao AS STRING) AS orgao,
      SAFE_CAST (NULL AS STRING) AS id_unidade_gestora,
      SAFE_CAST (NULL AS STRING) AS id_licitacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_licitacao,
      SAFE_CAST (ds_modalidade_lic AS STRING) AS modalidade_licitacao,
      SAFE_CAST (CONCAT(LEFT(nr_empenho, LENGTH(nr_empenho) - 5), cd_orgao, id_municipio, (RIGHT(ano_exercicio,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS id_empenho,
      SAFE_CAST (nr_empenho AS STRING) AS numero,
      SAFE_CAST (historico_despesa AS STRING) AS descricao,
      SAFE_CAST (NULL AS STRING) AS modalidade,
      CASE WHEN ds_funcao_governo = 'LEGISLATIVA'             THEN '1'
           WHEN ds_funcao_governo = 'JUDICIÁRIA'              THEN '2'
           WHEN ds_funcao_governo = 'ESSENCIAL À JUSTIÇA'     THEN '3'
           WHEN ds_funcao_governo = 'ADMINISTRAÇÃO'           THEN '4'
           WHEN ds_funcao_governo = 'DEFESA NACIONAL'         THEN '5'
           WHEN ds_funcao_governo = 'SEGURANÇA PÚBLICA'       THEN '6'
           WHEN ds_funcao_governo = 'RELAÇÕES EXTERIORES'     THEN '7'
           WHEN ds_funcao_governo = 'ASSISTÊNCIA SOCIAL'      THEN '8'
           WHEN ds_funcao_governo = 'PREVIDÊNCIA SOCIAL'      THEN '9'
           WHEN ds_funcao_governo = 'SAÚDE'                   THEN '10'
           WHEN ds_funcao_governo = 'TRABALHO'                THEN '11'  
           WHEN ds_funcao_governo = 'EDUCAÇÃO'                THEN '12' 
           WHEN ds_funcao_governo = 'CULTURA'                 THEN '13' 
           WHEN ds_funcao_governo = 'DIREITOS DA CIDADANIA'   THEN '14'
           WHEN ds_funcao_governo = 'URBANISMO'               THEN '15' 
           WHEN ds_funcao_governo = 'HABITAÇÃO'               THEN '16'
           WHEN ds_funcao_governo = 'SANEAMENTO'              THEN '17'  
           WHEN ds_funcao_governo = 'GESTÃO AMBIENTAL'        THEN '18'  
           WHEN ds_funcao_governo = 'CIÊNCIA E TECNOLOGIA'    THEN '19'
           WHEN ds_funcao_governo = 'AGRICULTURA'             THEN '20'
           WHEN ds_funcao_governo = 'ORGANIZAÇÃO AGRÁRIA'     THEN '21' 
           WHEN ds_funcao_governo = 'INDÚSTRIA'               THEN '22' 
           WHEN ds_funcao_governo = 'COMÉRCIO E SERVIÇOS'     THEN '23' 
           WHEN ds_funcao_governo = 'COMUNICAÇÕES'            THEN '24'
           WHEN ds_funcao_governo = 'ENERGIA'                 THEN '25' 
           WHEN ds_funcao_governo = 'TRANSPORTE'              THEN '26' 
           WHEN ds_funcao_governo = 'DESPORTO E LAZER'        THEN '27' 
           WHEN ds_funcao_governo = 'ENCARGOS ESPECIAIS'      THEN '28' 
           WHEN ds_funcao_governo = 'RESERVA DE CONTINGÊNCIA' THEN '99'
      END AS funcao,
      SAFE_CAST (subfuncao AS STRING) AS subfuncao,
      SAFE_CAST (cd_programa AS STRING) AS programa,
      SAFE_CAST (cd_acao AS STRING) AS acao,
      SAFE_CAST ((LEFT(ds_elemento,8)) AS STRING) AS elemento_despesa,
      SAFE_CAST (REPLACE(vl_despesa, ',', '.') AS FLOAT64) AS valor_inicial,
      NULL AS valor_reforco,
      NULL AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (REPLACE(vl_despesa, ',', '.') AS FLOAT64) AS valor_final
      -- CAST (valor_reforco AS FLOAT64) AS,
      -- CAST (valor_anulacao AS FLOAT64) AS,
      -- CAST (valor_empenho AS FLOAT64) AS
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_despesa_sp
    LEFT JOIN basedosdados.br_bd_diretorios_brasil.municipio m ON ds_municipio = nome
    LEFT JOIN `basedosdados-dev.mundo_bm_financas_publicas_staging.aux_subfuncao` ON ds_subfuncao_governo = UPPER(nome_subfuncao)
    WHERE tp_despesa = 'Empenhado' AND sigla_uf='SP'
),

  empenho_pe AS (
    SELECT
      SAFE_CAST (e.ANOREFERENCIA AS INT64) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE (DATAEMPENHO)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(DATAEMPENHO)) AS DATE) AS data,
      SAFE_CAST (UNIDADEFEDERATIVA AS STRING) AS sigla_uf, 
      SAFE_CAST (CODIGOIBGE AS STRING) AS id_municipio,
      SAFE_CAST (NULL AS STRING) orgao,
      SAFE_CAST (ID_UNIDADEGESTORA AS STRING) AS id_unidade_gestora,
      SAFE_CAST (NULL AS STRING) id_licitacao_bd,
      SAFE_CAST (NULL AS STRING) id_licitacao,
      SAFE_CAST (NULL AS STRING) modalidade_licitacao,
      SAFE_CAST (CONCAT(TRIM(ID_EMPENHO), ID_UNIDADEGESTORA, CODIGOIBGE, (RIGHT(e.ANOREFERENCIA,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (TRIM(ID_EMPENHO) AS STRING) AS id_empenho,
      SAFE_CAST (e.NUMEROEMPENHO AS STRING) AS numero,
      SAFE_CAST (LOWER(HISTORICO) AS STRING) AS descricao,
      SAFE_CAST (LEFT(TIPO_EMPENHO, 1) AS STRING) AS modalidade,
      SAFE_CAST (fun.funcao AS STRING) AS funcao,
      SAFE_CAST (sub.subfuncao AS STRING) AS subfuncao,
      SAFE_CAST (PROGRAMA AS STRING) AS programa,
      SAFE_CAST (CODIGO_TIPO_ACAO AS STRING) AS acao,
      CONCAT (
        CASE WHEN CATEGORIA = 'Despesa Corrente'   THEN '3'
             WHEN CATEGORIA = 'Despesa de Capital' THEN '4'
             END,
        CASE WHEN NATUREZA = 'Pessoal e Encargos Sociais' THEN '1'
             WHEN NATUREZA = 'Juros e Encargos da Dívida' THEN '2'
             WHEN NATUREZA = 'Outras Despesas Correntes'  THEN '3'
             WHEN NATUREZA = 'Investimentos'              THEN '4'
             WHEN NATUREZA = 'Inversões Financeiras'      THEN '5'
             WHEN NATUREZA = 'Amortização da Dívida'      THEN '6'
             WHEN NATUREZA = 'Reserva de Contingência'    THEN '9'
             END,
        CASE WHEN MODALIDADE = 'Transferências à União'                                         THEN '20'
             WHEN MODALIDADE = 'Transferências a Instituições Privadas com Fins Lucrativos'     THEN '30'
             WHEN MODALIDADE = 'Execução Orçamentária Delegada a Estados e ao Distrito Federal' THEN '32'
             WHEN MODALIDADE = 'Aplicação Direta à conta de recursos de que tratam os §§ 1o e 2o do art. 24 da Lei Complementar no 141, de 2012'                                                                                THEN '35'
             WHEN MODALIDADE = 'Aplicação Direta à conta de recursos de que trata o art. 25 da Lei Complementar no 141, de 2012'                                                                                           THEN '36'
             WHEN MODALIDADE = 'Transferências a Municípios'                                    THEN '40'
             WHEN MODALIDADE = 'Transferências a Municípios – Fundo a Fundo'                    THEN '41'
             WHEN MODALIDADE = 'Transferências a Instituições Privadas sem Fins Lucrativos'     THEN '50'
             WHEN MODALIDADE = 'Transferências a Instituições Privadas com Fins Lucrativos'     THEN '60'
             WHEN MODALIDADE = 'Transferências a Instituições Multigovernamentais'              THEN '70'
             WHEN MODALIDADE = 'Transferências a Consórcios Públicos mediante contrato de rateio à conta de recursos de que tratam os §§ 1o e 2o do art. 24 da Lei Complementar no 141, de 2012'                            THEN '71'
             WHEN MODALIDADE = 'Execução Orçamentária Delegada a Consórcios Públicos'           THEN '72'
             WHEN MODALIDADE = 'Transferências a Consórcios Públicos'                           THEN '73'
             WHEN MODALIDADE = 'Transferências ao Exterior'                                     THEN '80'
             WHEN MODALIDADE = 'Aplicações Diretas'                                             THEN '90'
             WHEN MODALIDADE = 'Ap. Direta Decor. de Op. entre Órg., Fundos e Ent. Integ. dos Orçamentos Fiscal e da Seguridade Social'                                                                                         THEN '91'
             WHEN MODALIDADE = ' Aplicação Direta Decor. de Oper. de Órgãos, Fundos e Entid. Integr. dos Orç. Fiscal e da Seguri. Social com Cons. Públ. do qual o Ente Participe'                                        THEN '93'
             WHEN MODALIDADE = ' Aplicação Direta Decor. de Oper. de Órgãos, Fundos e Entid. Integr. dos Orç. Fiscal e da Seguri. Social com Cons. Públ. do qual o Ente Não Participe'                                    THEN '94'
             ELSE NULL
             END,
        CASE WHEN ELEMENTODESPESA = 'Pensões do RPPS e do militar'                                  THEN '03'
             WHEN ELEMENTODESPESA = 'Contratação por Tempo Determinado'                             THEN '04'
             WHEN ELEMENTODESPESA = 'Outros Benefícios Previdenciários do RPPS'                     THEN '05'
             WHEN ELEMENTODESPESA = 'Outros Benefícios Previdenciários do servidor ou do militar'   THEN '05'
             WHEN ELEMENTODESPESA = 'Beneficio Mensal ao Deficiente e ao Idoso'                     THEN '06'
             WHEN ELEMENTODESPESA = 'Contribuição a Entidades Fechadas de Previdência'              THEN '07'
             WHEN ELEMENTODESPESA = 'Outros Benefícios Assistenciais'                               THEN '08'
             WHEN ELEMENTODESPESA = 'Outros Benefícios Assistenciais do servidor e do militar'      THEN '08'
             WHEN ELEMENTODESPESA = 'Salário Família'                                               THEN '09'
             WHEN ELEMENTODESPESA = 'Seguro Desemprego e Abono Salarial'                            THEN '10'
             WHEN ELEMENTODESPESA = 'Vencimentos e Vantagens Fixas - Pessoal Civil'                 THEN '11'
             WHEN ELEMENTODESPESA = 'Vencimentos e Vantagens Fixas - Pessoal Militar'               THEN '12'
             WHEN ELEMENTODESPESA = 'Obrigações Patronais'                                          THEN '13'
             WHEN ELEMENTODESPESA = 'Aporte para Cobertura do Déficit Atuarial do RPPS'             THEN '13'
             WHEN ELEMENTODESPESA = 'Diárias - Civil'                                               THEN '14'
             WHEN ELEMENTODESPESA = 'Outras Despesas Variáveis - Pessoal Civil'                     THEN '16'
             WHEN ELEMENTODESPESA = 'Auxílio Financeiro a Estudantes'                               THEN '18'
             WHEN ELEMENTODESPESA = 'Auxílio Fardamento'                                            THEN '19'
             WHEN ELEMENTODESPESA = 'Auxílio Financeiro a Pesquisadores'                            THEN '20'
             WHEN ELEMENTODESPESA = 'Outros Encargos sobre a Dívida por Contrato'                   THEN '22'
             WHEN ELEMENTODESPESA = 'Juros, Deságios e Descontos da Dívida Mobiliária'              THEN '23'
             WHEN ELEMENTODESPESA = 'Outros Encargos sobre a Dívida Mobiliária'                     THEN '24'
             WHEN ELEMENTODESPESA = 'Encargos sobre Operações de Crédito por Antecipação da Receita'THEN '25'
             WHEN ELEMENTODESPESA = 'Encargos pela Honra de Avais, Garantias, Seguros e Similares'                                                                                          THEN '27'
             WHEN ELEMENTODESPESA = 'Remuneração de Cotas de Fundos Autárquicos'                    THEN '28'
             WHEN ELEMENTODESPESA = 'Material de Consumo'                                           THEN '30'
             WHEN ELEMENTODESPESA = 'Premiações Culturais, Artísticas, Científicas, Desportivas e Outras'                                                                                             THEN '31'
             WHEN ELEMENTODESPESA = 'Material, Bem ou Serviço para Distribuição Gratuita'           THEN '32'
             WHEN ELEMENTODESPESA = 'Passagens e Despesas de Locomoção'                             THEN '33'
             WHEN ELEMENTODESPESA = 'Outras Despesas de Pessoal decorrentes de Contratos de Terceirização'                                                                                      THEN '34'
             WHEN ELEMENTODESPESA = 'Serviços de Consultoria'                                       THEN '35'
             WHEN ELEMENTODESPESA = 'Locação de Mão-de-Obra'                                        THEN '37'
             WHEN ELEMENTODESPESA = 'Outros Serviços de Terceiros ? Pessoa Jurídica'                THEN '39'
             WHEN ELEMENTODESPESA = 'Serviços de Tecnologia da Informação e Comunicação - Pessoa Jurídica'                                                                                           THEN '40'
             WHEN ELEMENTODESPESA = 'Serviços de Tecnologia da Informação e Comunicação ? Pessoa Jurídica'                                                                                           THEN '40'
             WHEN ELEMENTODESPESA = 'Contribuições'                                                 THEN '41'
             WHEN ELEMENTODESPESA = 'Auxílios'                                                      THEN '42'
             WHEN ELEMENTODESPESA = 'Obrigações Tributárias e Contributivas'                        THEN '47'
             WHEN ELEMENTODESPESA = 'Auxílio-Transporte'                                            THEN '49'
             WHEN ELEMENTODESPESA = 'Obras e Instalações'                                           THEN '51'
             WHEN ELEMENTODESPESA = 'Equipamentos e Material Permanente'                            THEN '52'
             WHEN ELEMENTODESPESA = 'Aposentadorias do RGPS ? Área Urbana'                          THEN '54'
             WHEN ELEMENTODESPESA = 'Pensões, exclusiva do RGPS'                                    THEN '56'
             WHEN ELEMENTODESPESA = 'Outros Benefícios do RGPS ? Área Urbana'                       THEN '58'
             WHEN ELEMENTODESPESA = 'Pensões Especiais'                                             THEN '59'
             WHEN ELEMENTODESPESA = 'Aquisição de Imóveis'                                          THEN '61'
             WHEN ELEMENTODESPESA = 'Constituição ou Aumento de Capital de Empresas'                THEN '65'
             WHEN ELEMENTODESPESA = 'Concessão de Empréstimos e Financiamentos'                     THEN '66'
             WHEN ELEMENTODESPESA = 'Depósitos Compulsórios'                                        THEN '67'
             WHEN ELEMENTODESPESA = 'Rateio pela Participação em Consórcio Público'                 THEN '70'
             WHEN ELEMENTODESPESA = 'Principal da Dívida Contratual Resgatado'                      THEN '71'
             WHEN ELEMENTODESPESA = 'Principal da Dívida Mobiliária Resgatado'                      THEN '72'
             WHEN ELEMENTODESPESA = 'Correção Monetária ou Cambial da Dívida Contratual Resgatada'  THEN '73'
             WHEN ELEMENTODESPESA = 'Principal Corrigido da Dívida Contratual Refinanciado'         THEN '77'
             WHEN ELEMENTODESPESA = 'Distribuição Constitucional ou Legal de Receitas'              THEN '81'
             WHEN ELEMENTODESPESA = 'Sentenças Judiciais'                                           THEN '91'
             WHEN ELEMENTODESPESA = 'Despesas de Exercícios Anteriores'                             THEN '92'
             WHEN ELEMENTODESPESA = 'Indenizações e Restituições'                                   THEN '93'
             WHEN ELEMENTODESPESA = 'Indenização pela Execução de Trabalhos de Campo'               THEN '95'
             WHEN ELEMENTODESPESA = 'Ressarcimento de Despesas de Pessoal Requisitado'              THEN '96'
             ELSE NULL
             END
            ) AS elemento_despesa,
      SAFE_CAST (VALOR AS FLOAT64) AS valor_inicial,
      NULL AS valor_reforco,
      NULL AS valor_anulacao,
      ROUND(SAFE_CAST (VALOR AS FLOAT64) - IFNULL(SAFE_CAST(VALOREMPENHADO AS FLOAT64),0),2) AS valor_ajsute,
      SAFE_CAST (VALOREMPENHADO AS FLOAT64) AS valor_final
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pe e
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_resumo_pe r ON RTRIM(ID_EMPENHO) = r.IDEMPENHO AND e.ID_UNIDADE_GESTORA =   r.ID_UNIDADE_GESTORA AND e.NUMEROEMPENHO = r.NUMEROEMPENHO
    INNER JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.raw_municipio_pe m ON e.ID_UNIDADE_GESTORA = ID_UNIDADEGESTORA
    LEFT JOIN `basedosdados-dev.mundo_bm_financas_publicas_staging.aux_funcao` fun ON UPPER(TRIM(REPLACE(REPLACE(e.FUNCAO, 'Encargos Especias', 'Encargos Especiais'), 'Assistêncial Social', 'Assistência Social'))) = UPPER(nome_funcao) 
    LEFT JOIN `basedosdados-dev.mundo_bm_financas_publicas_staging.aux_subfuncao` sub ON UPPER(TRIM(e.SUBFUNCAO)) = UPPER(nome_subfuncao)
),

  empenho_pr AS (
    SELECT
      SAFE_CAST (nrAnoEmpenho AS INT64) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE (dtEmpenho)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(dtEmpenho)) AS DATE) AS data,
      m.sigla_uf, 
      m.id_municipio,
      SAFE_CAST (TRIM(cdOrgao, '0') AS STRING) AS  orgao,
      SAFE_CAST (cdUnidade AS STRING) AS id_unidade_gestora,
      SAFE_CAST (NULL AS STRING) AS id_licitacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_licitacao,
      SAFE_CAST (NULL AS STRING) AS modalidade_licitacao,
      SAFE_CAST (CONCAT(idEmpenho, cdOrgao, m.id_municipio, (RIGHT(nrAnoEmpenho,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (idEmpenho AS STRING) AS id_empenho,
      SAFE_CAST (nrEmpenho AS STRING) AS numero,
      SAFE_CAST (LOWER (dsHistorico) AS STRING) AS descricao,
      SAFE_CAST (LEFT(dsTipoEmpenho, 1) AS STRING) AS modalidade,
      SAFE_CAST (CAST(cdFuncao AS INT64) AS STRING) AS funcao,
      SAFE_CAST (cdSubFuncao AS STRING) AS subfuncao,
      SAFE_CAST (cdPrograma AS STRING) AS programa,
      SAFE_CAST (cdProjetoAtividade AS STRING) AS acao,
      SAFE_CAST (CONCAT (cdCategoriaEconomica, cdGrupoNatureza, cdModalidade, cdElemento) AS STRING) AS elemento_despesa,
      SAFE_CAST (vlEmpenho AS FLOAT64) AS valor_inicial,
      NULL AS valor_reforco,
      SAFE_CAST (vlEstornoEmpenho AS FLOAT64) AS valor_anulacao,
      NULL AS valor_ajuste,
      ROUND(SAFE_CAST (vlEmpenho AS FLOAT64) - IFNULL(SAFE_CAST (vlEstornoEmpenho AS FLOAT64),0),2) AS valor_final
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pr 
    INNER JOIN basedosdados.br_bd_diretorios_brasil.municipio m ON cdIBGE = id_municipio_6
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas.relacionamentos ON idEmpenho = id_empenho
),

  empenho_rs AS (
    SELECT
        MIN(SAFE_CAST(ano_operacao AS INT64)) AS ano,
        SAFE_CAST(EXTRACT(MONTH FROM DATE (dt_empenho)) AS INT64) AS mes,
        SAFE_CAST(dt_empenho AS DATE) AS data,
        m.sigla_uf AS sigla_uf,
        SAFE_CAST(a.id_municipio AS STRING) AS id_municipio,
        SAFE_CAST(c.cd_orgao AS STRING) AS orgao,
        SAFE_CAST(cd_orgao_orcamentario AS STRING) AS id_unidade_gestora,
        SAFE_CAST(NULL AS STRING) AS id_licitacao_bd,
        SAFE_CAST(nr_licitacao AS STRING) AS id_licitacao,
        SAFE_CAST(mod_licitacao AS STRING) AS modalidade_licitacao,
        SAFE_CAST(CONCAT(nr_empenho, c.cd_orgao, m.id_municipio, (RIGHT(ano_operacao,2))) AS STRING) AS id_empenho_bd,
        SAFE_CAST(NULL AS STRING) AS id_empenho,
        SAFE_CAST(nr_empenho AS STRING) AS numero,
        SAFE_CAST(historico AS STRING) AS descricao,
        SAFE_CAST(NULL AS STRING) AS modalidade,
        SAFE_CAST(cd_funcao AS STRING) AS funcao,
        SAFE_CAST(cd_subfuncao AS STRING) AS subfuncao,
        SAFE_CAST(cd_programa AS STRING) AS programa,
        SAFE_CAST(cd_projeto AS STRING) AS acao,
        SAFE_CAST(cd_rubrica AS STRING) AS elemento_despesa,
        SAFE_CAST(NULL AS FLOAT64) AS valor_inicial,
        SAFE_CAST(NULL AS FLOAT64) AS valor_reforco,
        SAFE_CAST(NULL AS FLOAT64) AS valor_anulacao,
        SAFE_CAST(NULL AS FLOAT64) AS valor_ajuste,
        SAFE_CAST(vl_empenho AS FLOAT64) AS valor_final
      FROM `basedosdados-dev.mundo_bm_financas_publicas_staging.raw_despesa_rs` AS c
      LEFT JOIN `basedosdados-dev.mundo_bm_financas_publicas_staging.aux_orgao_rs` AS a ON c.cd_orgao = a.cd_orgao
      LEFT JOIN `basedosdados.br_bd_diretorios_brasil.municipio` m ON m.id_municipio = a.id_municipio
      WHERE tipo_operacao = 'E'
      GROUP BY 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
),
  empenho_pb AS (
SELECT
      SAFE_CAST (dt_Ano AS INT64) AS ano,
	SAFE_CAST(SUBSTRING(TRIM(dt_empenho),-7,2) AS INT64) AS mes,
      SAFE_CAST (CONCAT(SUBSTRING(TRIM(dt_empenho),-4),'-',SUBSTRING(TRIM(dt_empenho),-7,2),'-',SUBSTRING(TRIM(dt_empenho),1,2))AS DATE) AS data,
      m.sigla_uf, 
      m.id_municipio,
      SAFE_CAST (SUBSTRING(TRIM(cd_ugestora, '0'),1,1) AS STRING) AS  orgao,
      SAFE_CAST (cd_ugestora AS STRING) AS id_unidade_gestora, -- colocar aqui unidade_orcamentaria
      SAFE_CAST (NULL AS STRING) AS id_licitacao_bd,
      SAFE_CAST (NULL AS STRING) AS id_licitacao,
      SAFE_CAST (NULL AS STRING) AS modalidade_licitacao,
      SAFE_CAST (CONCAT(nu_Empenho, cd_ugestora, m.id_municipio, (RIGHT(dt_Ano,2))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS id_empenho,
      SAFE_CAST (nu_Empenho AS STRING) AS numero,
      SAFE_CAST (LOWER (de_Historico) AS STRING) AS descricao,
      SAFE_CAST (NULL AS STRING) AS modalidade,
      SAFE_CAST (funcao AS STRING) AS funcao,
      SAFE_CAST (subfuncao AS STRING) AS subfuncao,
      SAFE_CAST (de_Programa AS STRING) AS programa, --substituir por código
      SAFE_CAST (de_Acao AS STRING) AS acao, -- substituir por código
      CONCAT (
        CASE WHEN de_CatEconomica = 'Despesa Corrente'   THEN '3'
             WHEN de_CatEconomica = 'Despesa de Capital' THEN '4'
             WHEN de_CatEconomica = 'Reserva de Contingência' THEN '9'
             END,
        CASE WHEN de_NatDespesa = 'Pessoal e Encargos Sociais' THEN '1'
             WHEN de_NatDespesa = 'Juros e Encargos da Dívida' THEN '2'
             WHEN de_NatDespesa = 'Outras Despesas Correntes'  THEN '3'
             WHEN de_NatDespesa = 'Investimentos'              THEN '4'
             WHEN de_NatDespesa = 'Inversões Financeiras'      THEN '5'
             WHEN de_NatDespesa = 'Amortização da Dívida'      THEN '6'
             WHEN de_NatDespesa = 'Reserva de Contingência'    THEN '9'
             END,
        CASE WHEN de_Modalidade = 'Transferências à União'                                         THEN '20'
             WHEN de_Modalidade = 'Transferências a Instituições Privadas com Fins Lucrativos'     THEN '30'
             WHEN de_Modalidade = 'Execução Orçamentária Delegada a Estados e ao Distrito Federal' THEN '32'
             WHEN de_Modalidade = 'Aplicação Direta §§ 1º e 2º do Art. 24 LC 1412'                 THEN '35'
             WHEN de_Modalidade = 'Aplicação Direta Art. 25 LC 141'                                THEN '36'
             WHEN de_Modalidade = 'Transferências a Municípios'                                    THEN '40'
             WHEN de_Modalidade = 'Transferências a Municípios – Fundo a Fundo'                    THEN '41'
             WHEN de_Modalidade = 'Transferências a Instituições Privadas sem Fins Lucrativos'     THEN '50'
             WHEN de_Modalidade = 'Transferências a Instituições Privadas com Fins Lucrativos'     THEN '60'
             WHEN de_Modalidade = 'Transferências a Instituições Multigovernamentais'              THEN '70'
             WHEN de_Modalidade = 'Transf. a Consórc Púb. C.Rateio §§ 1º e 2º Art. 24  LC141'      THEN '71'
             WHEN de_Modalidade = 'Execução Orçamentária Delegada a Consórcios Públicos'           THEN '72'
             WHEN de_Modalidade = 'Transferências a Consórcios Públicos'                           THEN '73'
             WHEN de_Modalidade = 'Transf. a Consórc Púb. C.Rateio Art. 25 LC 141'                 THEN '74'
             WHEN de_Modalidade = 'Transferências ao Exterior'                                     THEN '80'
             WHEN de_Modalidade = 'Aplicações Diretas'                                             THEN '90'
             WHEN de_Modalidade = 'Ap. Direta Decor. de Op. entre Órg., Fundos e Ent. Integ. dos Orçamentos Fiscal e da Seguridade Social'                                                                                 THEN '91'
             WHEN de_Modalidade = ' Aplicação Direta Decor. de Oper. de Órgãos, Fundos e Entid. Integr. dos Orç. Fiscal e da Seguri. Social com Cons. Públ. do qual o Ente Participe'                                           THEN '93'
             WHEN de_Modalidade = ' Aplicação Direta Decor. de Oper. de Órgãos, Fundos e Entid. Integr. dos Orç. Fiscal e da Seguri. Social com Cons. Públ. do qual o Ente Não Participe'                                       THEN '94'
             ELSE NULL
             END,
        cd_elemento) AS elemento_despesa,
      NULL AS valor_inicial,
      NULL AS valor_reforco,
      NULL AS valor_anulacao,
      NULL AS valor_ajuste,
      SAFE_CAST (vl_Empenho AS FLOAT64) AS valor_final
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_pb e
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.aux_municipio_pb m ON e.cd_ugestora = m.id_unidade_gestora
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.aux_funcao f ON e.de_Funcao = f.nome_funcao
    LEFT JOIN basedosdados-dev.mundo_bm_financas_publicas_staging.aux_subfuncao sf ON e.de_Subfuncao = sf.nome_subfuncao
),
  empenho_ce AS (
    SELECT
      (SAFE_CAST(EXTRACT(YEAR FROM DATE (data_emissao_empenho)) AS INT64)) AS ano,
      (SAFE_CAST(EXTRACT(MONTH FROM DATE (data_emissao_empenho)) AS INT64)) AS mes,
      SAFE_CAST (EXTRACT(DATE FROM TIMESTAMP(data_emissao_empenho)) AS DATE) AS data,
      SAFE_CAST (sigla_uf AS STRING) AS sigla_uf, 
      SAFE_CAST (geoibgeId AS STRING) AS  id_municipio,
      SAFE_CAST ((CAST(codigo_orgao AS INT64)) AS STRING) AS orgao,
      SAFE_CAST (TRIM(codigo_unidade) AS STRING) AS id_unidade_gestora,
      SAFE_CAST (NULL AS STRING) AS id_licitacao_bd,
      SAFE_CAST (numero_licitacao AS STRING) AS id_licitacao,
      SAFE_CAST (tipo_processo_licitatorio AS STRING) AS modalidade_licitacao,
      SAFE_CAST (CONCAT(numero_empenho, TRIM(codigo_unidade), geoibgeId, (LEFT(data_referencia_empenho,4))) AS STRING) AS id_empenho_bd,
      SAFE_CAST (NULL AS STRING) AS id_empenho,
      SAFE_CAST (numero_empenho AS STRING) AS numero,
      SAFE_CAST (LOWER (descricao_empenho) AS STRING) AS descricao,
      SAFE_CAST (modalidade_empenho AS STRING) AS modalidade,
      SAFE_CAST (CAST(codigo_funcao AS INT64) AS STRING) AS funcao,
      SAFE_CAST (codigo_subfuncao AS STRING) AS subfuncao,
      SAFE_CAST (codigo_programa AS STRING) AS programa, --substituir por código
      SAFE_CAST (codigo_projeto_atividade AS STRING) AS acao, -- substituir por código
      SAFE_CAST (codigo_elemento_despesa AS STRING) AS modadlide_despesa,
      SAFE_CAST (valor_empenhado AS FLOAT64) AS valor_final,
      SAFE_CAST (valor_anterior_saldo_dotacao AS FLOAT64) AS valor_reforco,
      NULL AS valor_anulacao,
      SAFE_CAST (valor_atual_saldo_dotacao AS FLOAT64)- SAFE_CAST (valor_anterior_saldo_dotacao AS FLOAT64) AS valor_ajuste,
      SAFE_CAST (valor_empenhado AS FLOAT64) AS valor_final
    FROM basedosdados-dev.mundo_bm_financas_publicas_staging.raw_empenho_ce e

)

SELECT 
  *
FROM empenho_mg
UNION ALL (SELECT * FROM empenho_sp)
UNION ALL (SELECT * FROM empenho_pe)
UNION ALL (SELECT * FROM empenho_pr)
UNION ALL (SELECT * FROM empenho_rs)
UNION ALL (SELECT * FROM empenho_pb)
UNION ALL (SELECT * FROM empenho_ce)
)