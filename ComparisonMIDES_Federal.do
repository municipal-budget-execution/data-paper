use "/Users/tscot/Downloads/Portal-01-tender-panel.dta", clear

gen ano = substr(year_month , 1,4)
keep if ano == "2021"
gen log_amt = log(tender_amount)

gen federal = 1

keep federal log_amt tender_amount tender_objective

preserve
	import delim "/Users/tscot/Downloads/wordCloud_MG_lic.csv", clear
	
	gen log_amt = log(valor_corrigido)
	gen federal = 0
	
	rename (valor_corrigido  descricao_objeto) (tender_amount tender_objective)
	keep federal log_amt tender_amount tender_objective
	
	
	tempfile munic
	save "`munic'"
restore

append using "`munic'"

twoway (kdensity log_amt if federal == 1, color(dkorange)) ///
	 (kdensity log_amt if federal == 0, color(dknavy))
	 
	 
clear 

import delim "/Users/tscot/Dropbox/WBER_RR/Data/compare_Federal/Licitacoes_Mides_2021.csv", clear

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

tab sigla_uf modalidade_group [w=round(valor_corrigido)], nof row
tab sigla_uf modalidade_group , nof row

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

loc thr = log(17600)

twoway (kdensity log_amt if federal == 1, color(dknavy) lw(thick)) ///
		(kdensity log_amt  if federal == 0, color(dkorange) lw(thick)) ///
	(kdensity log_amt if sigla_uf == "CE", color(gs8%50) ) ///
 (kdensity log_amt if sigla_uf == "MG", color(gs8%50)) ///
  (kdensity log_amt if sigla_uf == "PB", color(gs8%50)) ///
   (kdensity log_amt if sigla_uf == "PE", color(gs8%50)) ///
    (kdensity log_amt if sigla_uf == "PR", color(gs8%50)) ///
	 (kdensity log_amt if sigla_uf == "RS", color(gs8%50)) if tender_amount >= 100, ///
	 legend(off) xline(`thr', lc(red) lw(thin)) xlab(, nogrid)

 tab sigla_uf modalidade_group, row nof
 
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
			xline(17600 33000) ylab(0(.2)1) xlab(0 10000 17600 20000 30000, nogrid labsize(small)) ytitle("Share of Bid Waivers") ///
			xtitle("Estimated tender value (R$)") legend(off) ///
			text(.84 5000 "Federal", color(dknavy)) text(.56 5000 "Municipal (MiDES)", color(dkorange))
restore
