## Replication package 

* MiDES: New Data and Facts from Local Procurement and Budget Execution in Brazil* 

### Overview

The code in this replication package constructs the analysis files from data provided by State Audit Courts (TCEs). Two master files execute all programs, one for Python scripts and the other for R scripts.

### Data

Our data is generated from State Audit Courts (TCEs _in portuguese_) with standardization efforts. Currently, we collect data from 7 Brazilian states based in disponibility and quality. 

State|Source
|-|-|
CE   |https://api-dados-abertos.tce.ce.gov.br/docs/  |
MG   |https://dadosabertos.tce.mg.gov.br |
PB   |https://dados.tce.pb.gov.br |
PE   |https://sistemas.tce.pe.gov.br/DadosAbertos |
PR   |https://servicos.tce.pr.gov.br/TCEPR/Tribunal/Relacon/Dados/DadosConsulta/Consolidado |
RS   |http://dados.tce.rs.gov.br |
SP   |https://transparencia.tce.sp.gov.br/conjunto-de-dados |
> [!NOTE]  
> We find budget execution and procurement data for all States in these links, less São Paulo State that provides procurement data just from 2018 to current day and not is included in our database

#### Data treatment

Each State makes the data available in a different way. Our work consists of creating a data architecture so that the variables have the same name and format. Not all States provide the same information, so there may be missing observations. Example: 

| name               | CE               | MG        | PB   | PE           | PR            | RS             | SP          |   |   |
|:--------------------:|:-------------------------:|:------------------:|:-------------:|:---------------------:|:----------------------:|:-----------------------:|:--------------------:|---|---|
| ano                | exercicio_orcamento     | num_anoexercicio | dt_Ano      | ANOREFERENCIA       | nrAnoEmpenho         | ano_operacao          | ano_exercicio      |   |   |
| mes                | data_referencia_empenho | num_mesexercicio |             |                     | nrMesProcessamento   |                       | mes_referencia     |   |   |
| data               | data_emissao_empenho    | dat_empenho      | dt_empenho  | DATA                | dtEmpenho            | dt_empenho            | dt_emissao_despesa |   |   |
| id_municipio       | codigo_municipio        | cod_municipio    |             |                     | cdIBGE               |                       | ds_municipio       |   |   |
| orgao              | codigo_orgao            | seq_orgao        |             | ID_UNIDADE_GESTORA  | cdOrgao; nmOrgao     | cd_orgao              | ds_orgao           |   |   |
| id_unidade_gestora | codigo_unidade          | cod_unidade      | cd_ugestora | UNIDADEORCAMENTARIA | cdUnidade; nmUnidade | cd_orgao_orcamentario |                    |   |   |



Furthermore, we created the id_bd, a unique identifier that allows a 1:1 match between tables. The creation of the id_bd guarantees the uniqueness of the information such as a primary key, however, in the absence of sufficient information, the id_bd assumes the value missing. The creation of the variable is nothing more than the joining of information from the table itself, such as id_municipio, entity, commitment number and year. In this replication package, we provide some of queries examples that use this join. 

We follow the methodology of Base dos Dados ([Dahis et al., 2022](https://osf.io/preprints/socarxiv/r76yg)) in harmonization schema and data lake storage. Base dos Dados is a non-profit organization with the mission to universalize access to high-quality data. They provide a platform in Google Cloud with more than 100 treated tables. Between the benefits, we can cross our data with population, GDP, companies, public treasure dataset, etc. 

For access database in BigQuery, you can follow this [steps](https://basedosdados.github.io/mais/access_data_bq/) to create a personal project and create your queries. The most simple query is

```sql
SELECT * FROM `basedosdados.world_wb_mides.empenho` LIMIT 100
```

The result is the 100 first observations of commitment table. But the scripts here provided differents queries that can be reproduced just changing the `project_id_bq`. 

### Requirements

* Access to Google Cloud Platform and the `basedosdados` project.
* Python 3.10.9 (all packages are as of 2023-09-06)
* R Studio 4.3 (all packages are as of 2023-09-06)

#### Runtime Requirements

Approximate time needed to reproduce the analyses on a standard 2023 machine: 8 minutes

### List of tables and programs

The provided code reproduces:

- [ ] All numbers provided in text in the paper
- [ ] All tables and figures in the paper
- [x] Selected tables and figures in the paper, as explained below.

Figures	| Label																		| File | 
| - | --- | ---  |
1		| Figure 1: Coverage of procurement and budget execution data | `Manually Created` |
2		| Figure 2: Example of procurement and budget execution process | `Manually Created` |
3		| Figure 3: Validation with SICONFI data - commitment	| `validation_siconfi_execution.ipynb` | 
4		| Figure 4: Validation with SICONFI data - verification	| `validation_siconfi_execution.ipynb` | 
5		| Figure 5: Validation with SICONFI data - payment	| `validation_siconfi_execution.ipynb` |
6		| Figure 6: Distribution of share of local suppliers across different states	| `home_bias_firms_characteristics.ipynb` |
7		| Figure 7: Distribution of share of local suppliers, by type of purchase	| `home_bias_firms_characteristics.ipynb` |
8		| Figure 8: Distribution of share of local suppliers, by population size	| `home_bias_firms_characteristics.ipynb` |
9		| Figure 9: Distribution of payment delays at municipality-year level	| `fig_and_reg_delay_payment.R`|
10		| Figure 10: Weighted average payment delay (days)	| `delay_payment_maps.ipynb` |
11		| Figure 11: Scatter plot - Average payment delay vs. GDP per capita	| `fig_reg_delay_payment.R` |
A1		| Figure A1: Validation with SICONFI data: commitment phase, by function	| `validation_siconfi_execution.ipynb` |
A2		| Figure A2: Validation with SICONFI data: verification phase, by function	| `validation_siconfi_execution.ipynb`|
A3		| Figure A3: Validation with SICONFI data: payment phase, by function	| `validation_siconfi_execution.ipynb` |
A4		| Figure A4: Validation with SICONFI data across years - payment	| `validation_siconfi_execution.ipynb` |
A5		| Figure A5: Share of payments paid over 30 days (%)	| `delay_payment_maps.ipynb` | 
A6		| Figure A6: Distribution of share of late payments (over 30 days)	| `fig_and_reg_delay_payment.R` |
A7		| Figure A7: Histogram of share of non-competitive tenders	| `example_paper.R` |
B1		| Figure B1: Missing tender identifiers 	| `null_ids.ipynb` |
B2		| Figure B2: Missing commitment identifiers	| `null_ids.ipynb` |
B3		| Figure B3: Missing verification identifiers	| `null_ids.ipynb` |
B4		| Figure B4: Missing payment identifiers	| `null_ids.ipynb` |
B5		| Figure B5: Missing municipalities: procurement	| `missing_municipalities.ipynb` |
B6		| Figure B6: Missing municipalities: budget execution	| `missing_municipalities.ipynb` |
B7		| Figure B7: Number of municipalities: commitment	| `total_municipalities.ipynb` |
B8		| Figure B8: Number of municipalities: verification	| `total_municipalities.ipynb` |
B9		| Figure B9: Number of municipalities: payment	| `total_municipalities.ipynb` |


| Tables |	Label |	File |
| -    | ---    | --- |
1	| Table 1: Procurement and budget execution coverage	| `Manually Created` | 
2	| Table 2: Descriptive statistics - public procurement	| `descriptive_statistics_procurement.ipynb` |
3	| Table 3: Descriptive statistics - budget execution | `descriptive_statistics_execution.ipynb` |
4	| Table 4: Correlates of deviations	| `fig_and_reg_delay_payment.R` |
5	| Table 5: Correlates of payment delays	| `fig_and_reg_delay_payment.R` |
A1	| Table A1: Procurement and budget execution sources	| `Manually Created` |
A2	| Table A2: Procurement methods	| `Manually Created` |
B1	| Table B1: Limitations in the budget execution data	| `Manually Created` |
B2	| Table B2: Limitations in the procurement data	| `Manually Created` |

## FAQ

* Where treatment data can be found?

The treatment data is available in Data Basis [repository](https://github.com/basedosdados/queries-basedosdados/tree/main/models/world_wb_mides/code) `queries-basedosdados`

* How connect procurement and budgext execution data?

Currently, PR is the only state that allows us to connect dataframes between `relacionamentos` table. Inclusive, we provide an example in our working paper. In other States we are studying the better way to include this information in table, if possible. 

* Why not all states have _id\_bd_?

Specifically, Pernambuco state doesn't have the id_bd created in treatment code. This is because the original data doesn't provide a unique identification that allows us to make this connection. Besides, we don't have all variables necessary to create the id_bd in all dataframes (commitment, verification and payment). 

* What the next steps in project?

We working in parallel to add new data sources, such as TCE from Rio de Janeiro and the Federal District. And improve the data including information about remains to be paid and the source of money.
