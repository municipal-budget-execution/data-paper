
** Thiago
if "`c(username)'" == "tscot" {
	global path_data "/Users/tscot/Dropbox/WBER_RR/Data"
	global path_figures "/Users/tscot/Dropbox/Aplicativos/Overleaf/MiDES - New Data and Facts from Brazil/figures"

}

** Bernardo
if "`c(username)'" == "" {
	global path_data   "C:\Dropbox\WBER_RR\Data"
}



use "${path_data}/data_fed2.dta", clear
gen valor=valorpagor+valorrestosapagarpagosr
keep if inlist(code_elemento,39,30,32,51,52,37,40,35)
collapse (sum) valor (first) nomeelementodedespesa, by(code_elemento)
egen tot=total(valor)
gen share=100*valor/tot
gsort -share
egen rank_sh=rank(-share)
replace valor=valor/10^9
rename nomeelementodedespesa conta
replace conta = "Other Services" if conta == "Outros Serviços de Terceiros - Pessoa Juríd"
replace conta = "Supplies and materials" if conta == "Material de Consumo"
replace conta = "Construction and Installations" if conta == "Obras e Instalações"
replace conta = "Equipment and Permanent Assets" if conta == "Equipamentos e Material Permanente"
replace conta = "Goods or Services for Free Distribution" if conta == "Material, Bem ou Serviço para Distribuição"
replace conta = "Consulting Services" if conta == "Serviços de Consultoria"
replace conta = "Labor Leasing" if conta == "Locação de Mão-de-Obra"
replace conta = "IT and Communication Services" if conta == "Serviços de Tecnologia da Informação e Com"
drop tot
order valor, after(conta)

gen sphere = "Federal"
preserve
	//STATES
	import delimited "${path_data}/finbra_state_elemento.csv", varnames(4) clear
	keep if coluna=="Despesas Pagas"
	drop id*
	drop coluna
	gen code_elemento=substr(conta,8,2)
	destring code_elemento, replace force
	keep if inlist(code_elemento,39,30,32,51,52,37,40,35)
	destring val*, dpcomma replace
	egen id=group(codibge code_elemento)
	collapse (sum) valor (first) conta (first) code_elemento (first) codibge, by(id)
	drop id
	fillin codibge code_elemento
	replace valor=0 if _fillin==1
	replace valor=valor/10^9
	bys codibge: egen tot=total(valor)
	gen share=100*valor/tot
	gsort code_elemento -conta
	collapse (sum) valor (first) conta (mean) share, by(code_elemento)
	gsort -share

	replace conta = "Other services" if code_elemento == 39 /*Outros Serviços de Terceiros - Pessoa Jurídica*/
	replace conta = "Supplies and materials" if code_elemento == 30 /*Material de Consumo*/
	replace conta = "Construction and installations" if code_elemento == 51 /*Obras e Instalações*/
	replace conta = "Equipment and permanent assets" if code_elemento == 52 /*Equipamentos e Material Permanente*/
	replace conta = "Goods or services for free distribution" if code_elemento == 32 /*Material, Bem ou Serviço para Distribuição Gratuita*/
	replace conta = "Consulting services" if code_elemento==  35 /*Serviços de Consultoria*/
	replace conta = "Labor leasing" if code_elemento == 37 /*Locação de Mão-de-Obra*/
	replace conta = "IT and communication services" if code_elemento == 40 /*Serviços de Tecnologia da Informação e Comunicação (TIC) - Pessoa Jurídica*/
	
	gen sphere = "State"
	
	tempfile state
	save "`state'"
restore

preserve
	//MUNICIPALITIES
	import delimited "${path_data}/finbra_municipality_elemento.csv", varnames(4) clear
	keep if coluna=="Despesas Pagas"
	drop id*
	drop coluna
	gen code_elemento=substr(conta,8,2)
	destring code_elemento, replace force
	keep if inlist(code_elemento,39,30,32,51,52,37,40,35)
	destring val*, dpcomma replace
	egen id=group(codibge code_elemento)
	collapse (sum) valor (first) conta (first) code_elemento (first) codibge, by(id)
	drop id
	fillin codibge code_elemento
	replace valor=0 if _fillin==1
	replace valor=valor/10^9
	bys codibge: egen tot=total(valor)
	gen share=100*valor/tot
	gsort code_elemento -conta
	collapse (sum) valor (first) conta (mean) share, by(code_elemento)
	gsort -share
	replace conta = "Other Services" if code_elemento == 39 /*Outros Serviços de Terceiros - Pessoa Jurídica*/
	replace conta = "Supplies and materials" if code_elemento == 30 /*Material de Consumo*/
	replace conta = "Construction and Installations" if code_elemento == 51 /*Obras e Instalações*/
	replace conta = "Equipment and Permanent Assets" if code_elemento == 52 /*Equipamentos e Material Permanente*/
	replace conta = "Goods or Services for Free Distribution" if code_elemento == 32 /*Material, Bem ou Serviço para Distribuição Gratuita*/
	replace conta = "Consulting Services" if code_elemento==  35 /*Serviços de Consultoria*/
	replace conta = "Labor Leasing" if code_elemento == 37 /*Locação de Mão-de-Obra*/
	replace conta = "IT and Communication Services" if code_elemento == 40 /*Serviços de Tecnologia da Informação e Comunicação (TIC) - Pessoa Jurídica*/
	
	gen sphere = "Municipality"
	
	tempfile munic
	save "`munic'"
restore

append using "`state'"
append using "`munic'"


***Share of AGGREGATE expenditure
preserve
	drop conta share rank_sh
	reshape wide valor, i(sphere) j(code_elemento) 

	graph bar valor39 valor30 valor51 valor52 valor32 valor35 valor37 valor40, over(sphere, sort(valor39)) stack percent ///
		legend(lab (1 "Other Services") lab (2 "Supplies and materials" ) lab (3 "Construction" ) ///
		lab (4 "Equipment and permanent assets" ) lab (5 "Goods for Free distribution") lab (6 "Consulting Services" ) ///
		lab (7 "Labor hiring" ) lab (8 "IT and Communication Services") pos(6) col(3))
		
restore


***Share of AGGREGATE expenditure
preserve
	drop conta share rank_sh
	reshape wide valor, i(sphere) j(code_elemento) 
	
	gen services = valor39 + valor35 + valor40
	gen materials = valor30 + valor32
	gen construction = valor51
	gen equipment = valor52
	gen labor_lease = valor37
	
	
	graph bar services construction  labor_lease materials    equipment  , over(sphere, sort(valor39)) stack percent ///
		legend(lab (1 "Services") lab (2 "Construction" ) lab (3 "Labor hiring" )  ///
		lab (4 "Goods and materials" )  lab (5 "Equipment & Assets" )  pos(6) col(3))
	graph export "${path_figures}/composition_levels_expenditures.png", replace as(png)	
restore

***Share of AVERAGE expenditure
preserve
	drop conta valor  rank_sh
	reshape wide share, i(sphere) j(code_elemento) 

	graph bar share39 share30 share51 share52 share32 share35 share37 share40, over(sphere, sort(share39)) stack  ///
		legend(lab (1 "Other Services") lab (2 "Supplies and materials" ) lab (3 "Construction" ) ///
		lab (4 "Equipment and permanent assets" ) lab (5 "Goods for Free distribution") lab (6 "Consulting Services" ) ///
		lab (7 "Labor hiring" ) lab (8 "IT and Communication Services") pos(6) col(3))
		
restore
