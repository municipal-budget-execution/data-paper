//********************************************************************//
// MiDES - New Data and Facts from Brazil
// Application - RDD  close election 
// Outcomes:  % of purchases of local suppliers
// % of purchases as non-competitive tenders
//********************************************************************//

* Nathalia
	if "`c(username)'" == "nathaliasales"  {
		global code_path 		"/Users/nathaliasales/Documents/GitHub/data-paper"
		global input_path 		"/Users/nathaliasales/Documents/MiDES-data-paper-replication/Data"		
		global output_path 	"/Users/nathaliasales/Dropbox/MiDES-data-paper-replication/Output" 
	}

//****************************//
//  Open tender level data 
//****************************//

import delimited "${input_path}/Raw/licitacao.csv", clear

** Calculate % of non-competitive tenders by municipality
gen discret_tender = (modalidade == 8 | modalidade == 10) 

* So far we dont have mayors information for 2021 
drop if ano == 2021 

gen term = .
replace term = 2009 if inrange(ano, 2009, 2012)
replace term = 2013 if inrange(ano, 2013, 2016)
replace term = 2017 if inrange(ano, 2017, 2020)

collapse (mean) discret_tender, by(id_municipio term sigla_uf)

ren id_municipio municipality_id

tempfile non_competitive_tenders
	save `non_competitive_tenders'

//**********************************//
//  Open participants data 
//**********************************//

** Participants data merged with cnpj ministry dataset

import delimited "${input_path}/Raw/participante_cnpj.csv", clear

** Find participants in same municipality
gen same_municipality = id_municipio == id_municipio_1

* Keep only winners
keep if vencedor == 1

* So far we dont have mayors information for 2021 
drop if ano == 2021 

gen term = .
replace term = 2009 if inrange(ano, 2009, 2012)
replace term = 2013 if inrange(ano, 2013, 2016)
replace term = 2017 if inrange(ano, 2017, 2020)

** Calculate % of local tenders tenders by municipality
collapse (mean) same_municipality, by(id_municipio term sigla_uf)

ren id_municipio municipality_id

tempfile local_tenders
	save `local_tenders'
	
//**********************************//
//  Open mayors data 
//**********************************//

use "${input_path}/Intermediate/mayors.dta", clear

//generate dummies for first term
gen first=.
replace first=0 if term_number==2
replace first=1 if term_number==1

//generate party dummies for most common parties (parties with more than 50 observation
foreach party in PDT PFL PL PMDB PP PPS PSB PSDB PT PTB {
gen party_`party'=party=="`party'"
}
gen party_other=1
foreach party in PDT PFL PL PMDB PP PPS PSB PSDB PT PTB {
replace party_other=0 if party_`party'==1
}

//generate gender dummies
gen male=gender=="masculino"
gen female=gender=="feminino"

//Generate dummies for different levels of schooling
gen schooling_1=education=="le e escreve"
gen schooling_2=education=="ensino fundamental incompleto"
gen schooling_3=education=="ensino fundamental completo"
gen schooling_4=education=="ensino medio incompleto"
gen schooling_5=education=="ensino medio completo"
gen schooling_6=education=="ensino superior incompleto"
gen schooling_7=education=="ensino superior completo"
gen schooling_missing=education=="NA"

//I will use the age_missing dummy when age is missing so therefore I can set missing values to zero
destring age, replace force 
gen age_missing=age==.
replace age=0 if age==.
gen age2=age^2
gen age3=age^3

* gen running variable
gen wm = win_margin if first==0
replace wm =  winmargin_inclost if inclost==1
replace wm = wm/100

gen running = -wm
replace running = wm if inclost==1
	
* Keep years for which we have procurement data	
keep if year>= 2008

tempfile mayors
	save `mayors'

//**********************************//
//  Merge all
//**********************************//

use `non_competitive_tenders', clear

merge 1:1 municipality_id term using `local_tenders', gen(merge1)

merge 1:1 municipality_id term using `mayors', gen(merge2) keepusing(uf term_number first inclost running schooling_* male age* party_*)
drop if merge2==2

//**********************************//
//  RDD
//**********************************//

eststo clear

local depvars discret_tender same_municipality

		foreach Y_dep in `depvars' {

			qui rdbwselect `Y_dep' running covs(schooling_* male age* party_* i.uf), c(0) p(1)
			local bwidth: di e(h_mserd)
			
			eststo reg_`Y_dep'_1: qui rdrobust `Y_dep' running covs(schooling_* male age* party_* i.uf), c(0) p(1) h(`bwidth'  `bwidth')
			estadd local bwsel "CCT"

			eststo reg_`Y_dep'_2: qui rdrobust `Y_dep' running covs(schooling_* male age* party_* i.uf), c(0) p(1) h((`bwidth')/2  (`bwidth')/2)
			estadd local bwsel ".5CCT"
			
			eststo reg_`Y_dep'_3: qui rdrobust `Y_dep' running covs(schooling_* male age* party_* i.uf), c(0) p(1) h((`bwidth')*2  (`bwidth')*2)
			estadd local bwsel "2CCT"

			}	

	esttab reg_discret_tender_1 reg_discret_tender_2 reg_discret_tender_3 reg_same_municipality_1 reg_same_municipality_2 reg_same_municipality_3 ///
		using "${output_path}/Tables/RDD_mayors.tex", ///
		coeflabels(RD_Estimate "First term mayor") star(* 0.10 ** 0.05 *** 0.01) replace ///
		booktabs cells(b(star fmt(3) vacant({--})) se(par(( )) fmt(3))) ///
		stats(ci_rb kernel bwsel h_r N, fmt(0 0 0 3 0)	///
		labels(`"Robust 90\% CI"' `"Kernel Type"' `"BW Type"' `"BW"' `"Observations"')) ///
		mgroups("\% Non-competitive tenders" "\% Tenders with local supplier", ///
		pattern(1 0 0 1 0 0) span prefix(\multicolumn{3}{c}{)suffix(})) nonotes compress nomtitle collabels(none) 

** graph

label var discret_tender "% Non-competitive tenders"
label var same_municipality "% Tenders with local supplier"

local depvars discret_tender same_municipality

	foreach Y_dep in `depvars' {

		qui rdrobust `Y_dep' running covs(schooling_* male age* party_* i.uf), c(0) p(1) bwselect(mserd)
		local rbwidth: di e(h_r)
		local lbwidth: di e(h_l)
			
		cmogram `Y_dep' running if inrange(running,- e(h_l), e(h_l)), cut(0) lfitci scatter ciopts(90) lineat(0) ///
		graphopts(xtitle(Margin of victory, size(*1.2)) ytitle("`: variable label `Y_dep''", size(*1.2)) ///
		xlabel(, labsize(*1.2)) ylabel(, labsize(*1.2)) graphregion(color(white))) 
		graph export "${output_path}/Figures/rdplot_`Y_dep'.pdf", replace  
		
	}
