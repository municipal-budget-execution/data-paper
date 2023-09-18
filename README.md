## Replication package 

* MiDES: New Data and Facts from Local Procurement and Budget Execution in Brazil* 

### Overview

The code in this replication package constructs the analysis files from data provided by State Audit Courts (TCEs). Two master files execute all programs, one for Python scripts and the other for R scripts.

### Requirements

* Access to Google Cloud Platform and the `basedosdados-dev` project.
* Python 3 (all packages are as of 2023-09-06)
* R Studio (all packages are as of 2023-09-06)

#### Runtime Requirements

Approximate time needed to reproduce the analyses on a standard 2023 machine: 8 minutes

### List of tables and programs

The provided code reproduces:

- [ ] All numbers provided in text in the paper
- [ ] All tables and figures in the paper
- [x] Selected tables and figures in the paper, as explained below.

Figures	| Label																		| File | 
| - | --- | ---  |
1			| Figure 1: Coverage of procurement and budget execution data | `Manually Created` |
2			| Figure 2: Example of procurement and budget execution process | `Manually Created` |
3			| Figure 3: Validation with SICONFI data - commitment	| `validation_siconfi_execution.ipynb` | 
4			| Figure 4: Validation with SICONFI data - verification	| `validation_siconfi_execution.ipynb` | 
5			| Figure 5: Validation with SICONFI data - payment	| `validation_siconfi_execution.ipynb` |
6			| Figure 6: Distribution of share of local suppliers across different states	| `home_bias_firms_characteristics.ipynb` |
7			| Figure 7: Distribution of share of local suppliers, by type of purchase	| `home_bias_firms_characteristics.ipynb` |
8			| Figure 8: Distribution of share of local suppliers, by population size	| `home_bias_firms_characteristics.ipynb` |
9			| Figure 9: Distribution of payment delays at municipality-year level	| `fig_and_reg_delay_payment.R`|
10			| Figure 10: Weighted average payment delay (days)	| `delay_payment_maps.ipynb` |
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

* 
* 