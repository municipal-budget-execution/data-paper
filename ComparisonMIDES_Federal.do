

global path_data "/Users/tscot/Dropbox/MiDES-data-paper-replication/Data"
global path_figures "/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures"


clear 

import delim "$path_data/Intermediate/mides_2021_tenders.csv", clear

gen modalidade_group = .
replace modalidade_group = 1 if modalidade == 8
replace modalidade_group = 2 if inlist(modalidade, 4,5,6)
replace modalidade_group = 3 if inlist(modalidade, 10)
replace modalidade_group = 4 if inlist(modalidade, 2)
replace modalidade_group = 5 if modalidade_group == .

lab def modalidade_group 1 "Waiver" 2 "Auctions" 3 "Direct Contracting" 4 "Submission of Prices" 5 "Other"
lab val modalidade_group modalidade_group

*Few negative values
replace valor_orcamento = . if valor_orcamento < 0

gen log_amt = log(valor_orcamento)

preserve
	import delim "$path_data/Intermediate/Transparency_Federal_2021/licitacoes_2021.csv", clear

	gen log_amt = log(valor_licitacao)

	gen federal = 1
	
	gen modalidade_group = .
	replace modalidade_group = 1 if codigo_modalidade_compra == 6
	replace modalidade_group = 2 if inlist(codigo_modalidade_compra, 9999,9997,5)
	replace modalidade_group = 3 if inlist(codigo_modalidade_compra,7)
	replace modalidade_group = 4 if inlist(codigo_modalidade_compra, 2)
	replace modalidade_group = 5 if modalidade_group == .

	lab def modalidade_group 1 "Waiver" 2 "Auctions" 3 "Direct Contracting" 4 "Submission of Prices" 5 "Other"
	lab val modalidade_group modalidade_group

	rename (valor_licitacao objeto)(tender_amount tender_objective) 
	keep federal log_amt tender_amount tender_objective modalidade_group
	
	tempfile federal
	save "`federal'"

restore

rename (valor_orcamento descricao_objeto) (tender_amount tender_objective) 

append using "`federal'"

replace federal = 0 if federal == .
replace sigla_uf = "Federal" if sigla_uf == ""



gen service = regexm(upper(tender_objective), ///
   "SERVIÇO|SERVICO|ALUGUEL|ALUGUÉL|MANUTENÇÃO|MANUTENCAO|CONSULTORIA|ASSESSORIA|TREINAMENTO|CAPACITAÇÃO|CAPACITACAO|TRANSPORTE|FRETE|LOCAÇÃO|LOCACAO|LICENCIAMENTO|SUPORTE|INSTALAÇÃO|INSTALACAO|LIMPEZA|SEGURANÇA|SEGURANCA|VIGILÂNCIA|VIGILANCIA|MONITORAMENTO|DESENVOLVIMENTO|PROGRAMACAO|PROGR|SHOW|OBRA")

	
	

loc thr = log(17600)
twoway (kdensity log_amt if federal == 1, color(dknavy) lw(thick)) ///
		(kdensity log_amt  if federal == 0, color(dkorange) lw(thick)) ///
	(kdensity log_amt if sigla_uf == "CE", color(gs8%20) lp(dash)) ///
 (kdensity log_amt if sigla_uf == "MG", color(gs8%20) lp(dash)) ///
  (kdensity log_amt if sigla_uf == "PB", color(gs8%20)lp(dash)) ///
   (kdensity log_amt if sigla_uf == "PE", color(gs8%20)lp(dash)) ///
    (kdensity log_amt if sigla_uf == "PR", color(gs8%20)lp(dash)) ///
	 (kdensity log_amt if sigla_uf == "RS", color(gs8%20)lp(dash)) if tender_amount >= 100, ///
	 legend(off) xline(`thr', lc(red) lw(thin)) xlab(, nogrid) ylab(, nogrid) ///
	 ytitle("Density") xtitle("Log(Tender Value)") ///
	 text(.22 7 "Federal (Transparency Portal)", size(vsmall) color(dknavy)) ///
	 text(0.15 15 "Municipal (MiDES)", size(vsmall) color(dkorange))
graph export "${path_figures}/distribution_tender_federal.png", replace as(png)	


**Only states for which we also have items
loc thr = log(17600)
twoway (kdensity log_amt if federal == 1, color(dknavy) lw(thick)) ///
		(kdensity log_amt  if (federal == 0 & inlist(sigla_uf, "CE", "MG", "RS")), color(dkorange) lw(thick)) ///
	(kdensity log_amt if sigla_uf == "CE", color(gs8%20) lp(dash)) ///
 (kdensity log_amt if sigla_uf == "MG", color(gs8%20) lp(dash)) ///
    (kdensity log_amt if sigla_uf == "PR", color(gs8%20)lp(dash)) ///
	 (kdensity log_amt if sigla_uf == "RS", color(gs8%20)lp(dash)) if tender_amount >= 100, ///
	 legend(off) xline(`thr', lc(red) lw(thin)) xlab(, nogrid) ylab(, nogrid) ///
	 ytitle("Density") xtitle("Log(Tender Value)") ///
	 text(.22 7 "Federal (Transparency Portal)", size(vsmall) color(dknavy)) ///
	 text(0.15 15 "Municipal (MiDES)", size(vsmall) color(dkorange))
graph export "${path_figures}/distribution_tender_federal_itemsonly.png", replace as(png)	



tab sigla_uf modalidade_group [w=round(tender_amount)] if tender_amount < 100e9 , nof row
tab sigla_uf modalidade_group , nof row

encode sigla_uf, gen(uf)
gen amt_million = tender_amount/1e6


gen waiver = modalidade_group  == 1

preserve
	keep if inrange(tender_amount, 2600, 42600)
	egen quantiles = cut(tender_amount), at(2600(500)42600)
	gcollapse (mean) waiver, by(quantiles federal)
	
	twoway (connect waiver quantiles if federal == 1, color(dknavy) lw(medthick)) ///
			(connect waiver quantiles if federal == 0, color(dkorange)lw(medthick)), ///
			xline(17600 33000) ylab(0(.2)1) xlab(0 10000 17600  33000, nogrid labsize(small) format(%9.0fc)) ytitle("Share of Waivers") ///
			xtitle("Estimated tender value (R$)") legend(off) ///
			text(.85 5200 "Federal (Transparency Portal)", size(small) color(dknavy)) text(.56 5200 "Municipal (MiDES)", size(small) color(dkorange))
	graph export "${path_figures}/waiver_thresholds.png", replace as(png)		
	
restore

preserve
	keep if inrange(tender_amount, 2600, 42600)
	egen quantiles = cut(tender_amount), at(2600(250)42600)
	
	gcollapse (count) number = tender_amount, by(quantiles federal)
	bys federal: egen tot = total(number)
	gen share = number/tot
	gsort federal quantiles
	
	twoway (connect share quantiles if federal == 1, color(dknavy) lw(medthick) ) ///
			(connect share quantiles if federal == 0, color(dkorange%60)lw(medthick)), ///
			xline(17600 33000) xlab(0 10000 17600  33000, nogrid labsize(small) format(%9.0fc)) ytitle("Share of Tenders") ///
			xtitle("Estimated tender value (R$)") legend(off) ///
			text(.035 9200 "Federal (Transparency Portal)", size(small) color(dknavy)) text(0.007 5200 "Municipal (MiDES)", size(small) color(dkorange))
	graph export "${path_figures}/waiver_thresholds_bunching.png", replace as(png)		
	
restore


***Comparing items


import delim "$path_data/Intermediate/mides_2021_items.csv", clear
drop if sigla_uf == "PR"
gen federal = 0

preserve
	import delim "$path_data/Intermediate/Transparency_Federal_2021/licitacoes_items_2021.csv", clear

	keep numero_licitacao codigo_ug valor_item
	gen federal = 1

	tostring numero_licitacao, gen(num_lic_str)
	tostring codigo_ug, gen(ug_str)
	gen id_licitacao_bd = num_lic_str + ug_str
	
	tempfile federal
	save "`federal'"

restore

append using "`federal'"


gen log_amt = log(valor_item)

preserve
	sample 20 
	 summ valor_item if federal == 0, d
	 summ valor_item if federal == 1, d

	twoway (kdensity log_amt if federal == 1, color(dknavy) lw(thick)) ///
			(kdensity log_amt  if federal == 0, color(dkorange) lw(thick)) ///
		(kdensity log_amt if sigla_uf == "CE", color(gs8%20) lp(dash)) ///
	 (kdensity log_amt if sigla_uf == "MG", color(gs8%20) lp(dash)) ///
		 (kdensity log_amt if sigla_uf == "RS", color(gs8%20)lp(dash)) if valor_item >= 10, ///
		 legend(off) xlab(, nogrid) ylab(, nogrid) ///
		 ytitle("Density") xtitle("Log(Tender Value)") ///
		 text(.18 11 "Federal (Transparency Portal)", size(vsmall) color(dknavy)) ///
		 text(0.18 3 "Municipal (MiDES)", size(vsmall) color(dkorange))
	graph export "${path_figures}/distribution_items_federal.png", replace as(png)	
restore

preserve
	gen unit = 1
	gcollapse (count) count_items = unit, by(id_licitacao_bd federal)
	
	summ count_items
	summ count_items if federal == 1, d
	summ count_items if federal == 0, d
// 	twoway (histogram count_items if federal == 1, color(dknavy) w(1)) ///
// 		(histogram count_items if federal == 0, color(dkorange%20) w(1)) if count_items < 100
restore
