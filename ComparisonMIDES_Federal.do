
global path_figures "/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures"



	 
	 
clear 

import delim "/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/mides_2021_tenders.csv", clear

gen modalidade_group = .
replace modalidade_group = 1 if modalidade == 8
replace modalidade_group = 2 if inlist(modalidade, 4,5,6)
replace modalidade_group = 3 if inlist(modalidade, 10)
replace modalidade_group = 4 if inlist(modalidade, 2)
replace modalidade_group = 5 if modalidade_group == .

lab def modalidade_group 1 "Waiver" 2 "Auctions" 3 "Direct Contracting" 4 "Submission of Prices" 5 "Other"
lab val modalidade_group modalidade_group

*Few negative values
replace valor_corrigido = . if valor_corrigido < 0

gen log_amt = log(valor_corrigido)

preserve
	use "/Users/tscot/Downloads/Portal-01-tender-panel.dta", clear

	gen ano = substr(year_month , 1,4)
	keep if ano == "2021"
	gen log_amt = log(tender_amount)

	gen federal = 1
	
	gen modalidade_group = .
	replace modalidade_group = 1 if purchase_method_name == "dispensa de licitacao"
	replace modalidade_group = 2 if inlist(purchase_method_name, "pregao", "pregao - registro de preco")
	replace modalidade_group = 3 if inlist(purchase_method_name, "inexigibilidade de licitacao")
	replace modalidade_group = 4 if inlist(purchase_method_name, "tomada de precos")
	replace modalidade_group = 5 if modalidade_group == .

	lab def modalidade_group 1 "Waiver" 2 "Auctions" 3 "Direct Contracting" 4 "Submission of Prices" 5 "Other"
	lab val modalidade_group modalidade_group

	keep federal log_amt tender_amount tender_objective modalidade_group
	
	tempfile federal
	save "`federal'"

restore

rename (valor_corrigido descricao_objeto) (tender_amount tender_objective) 

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


loc thr = log(17600)
twoway (kdensity log_amt if federal == 1 & service == 1, color(dknavy) lw(thick)) ///
	(kdensity log_amt if federal == 1 & service == 0, color(dkgreen) lw(thick)) ///
	(kdensity log_amt  if federal == 0 & service == 1, color(dkorange) lw(thick)) ///
		(kdensity log_amt  if federal == 0 & service == 0, color(maroon) lw(thick)) ///
		if tender_amount >= 100, ///
	 legend(off) xline(`thr', lc(red) lw(thin)) xlab(, nogrid)
	 
	 

tab sigla_uf modalidade_group [w=round(tender_amount)] if tender_amount < 100e9 , nof row
tab sigla_uf modalidade_group , nof row

encode sigla_uf, gen(uf)
gen amt_million = tender_amount/1e6


gen waiver = modalidade_group  == 1

preserve
	keep if inrange(tender_amount, 2600, 32600)
	egen quantiles = cut(tender_amount), at(2600(1000)32600)
	gcollapse (mean) waiver, by(quantiles sigla_uf)
	
	twoway (connect waiver quantiles if sigla_uf == "Federal", color(dknavy)) (connect waiver quantiles if sigla_uf == "RS", color(dkorange)) ///
			(connect waiver quantiles if sigla_uf == "MG", color(dkgreen)) (connect waiver quantiles if sigla_uf == "PB", color(gs8)), ///
			xline(17600)
restore

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
			(connect share quantiles if federal == 0, color(dkorange%80)lw(medthick)), ///
			xline(17600 33000) xlab(0 10000 17600  33000, nogrid labsize(small) format(%9.0fc)) ytitle("Share of Tenders") ///
			xtitle("Estimated tender value (R$)") legend(off) ///
			text(.035 9200 "Federal (Transparency Portal)", size(small) color(dknavy)) text(0.007 5200 "Municipal (MiDES)", size(small) color(dkorange))
	graph export "${path_figures}/waiver_thresholds_bunching.png", replace as(png)		
	
restore

gen value_wins = min(tender_amount, 1e9)
mean service [w = round(value_wins)], over(federal)




***Comparing items


import delim "/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/mides_2021_items.csv", clear

gen federal = 0
preserve
	import delim "/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/202107_Licitacoes/202107_ItemLicitação.csv", clear
	
	destring valoritem, gen(valor_total)  dpcomma
	
	keep códigoug valor_total
	gen federal = 1
		
	tempfile federal
	save "`federal'"

restore

append using "`federal'"


gen log_amt = log(valor_total)

preserve
	*sample 5 
	
	loc thr = log(17600)
	twoway (kdensity log_amt if federal == 1, color(dknavy) lw(thick)) ///
			(kdensity log_amt  if federal == 0, color(dkorange) lw(thick)) ///
		(kdensity log_amt if sigla_uf == "CE", color(gs8%20) lp(dash)) ///
	 (kdensity log_amt if sigla_uf == "MG", color(gs8%20) lp(dash)) ///
	  (kdensity log_amt if sigla_uf == "PB", color(gs8%20)lp(dash)) ///
	   (kdensity log_amt if sigla_uf == "PE", color(gs8%20)lp(dash)) ///
		(kdensity log_amt if sigla_uf == "PR", color(gs8%20)lp(dash)) ///
		 (kdensity log_amt if sigla_uf == "RS", color(gs8%20)lp(dash)) if valor_total >= 10, ///
		 legend(off) xline(`thr', lc(red) lw(thin)) xlab(, nogrid) ylab(, nogrid) ///
		 ytitle("Density") xtitle("Log(Tender Value)") ///
		 text(.18 11 "Federal (Transparency Portal)", size(vsmall) color(dknavy)) ///
		 text(0.18 3 "Municipal (MiDES)", size(vsmall) color(dkorange))
	graph export "${path_figures}/distribution_items_federal.png", replace as(png)	
restore



import delim "/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/202107_Licitacoes/202107_Licitação.csv", clear

destring valorlicitação, gen(valor_total_lic)  dpcomma
summ valor_total_lic, d

*Random dropping few duplicate tenders
duplicates drop númerolicitação códigoug, force

rename (númerolicitação códigoug) (id_tender id_ug)
preserve
	import delim "/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/202107_Licitacoes/202107_ItemLicitação.csv", clear
	
	destring valoritem, gen(valor_total)  dpcomma
	gen unit = 1
	gcollapse (sum) mean_value_items =valor_total (mean) mean_value = valor_total (count) N = unit, by(númerolicitação códigoug)
	
	gen federal = 1
	
	rename (númerolicitação códigoug) (id_tender id_ug)
	
	tempfile federal
	save "`federal'"

restore

merge 1:1 id_tender id_ug using "`federal'"
