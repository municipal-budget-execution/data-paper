//********************************************************************//
// MiDES - New Data and Facts from Brazil 
// Goal: identify the percentage of municipal UASG available 
// in comprasdados data
//********************************************************************//

	* Nathalia
	if "`c(username)'" == "nathaliasales"  {
		global code_path   "/Users/nathaliasales/Documents/GitHub/data-paper"
		global input_path  "/Users/nathaliasales/Dropbox/MiDES-data-paper-replication/Data"		
		global output_path "/Users/nathaliasales/Dropbox/MiDES-data-paper-replication/Output" 
	}

	**** Compras dados ug/orgao list

	import delimited "${input_path}/Raw/comprasdados/uasg.csv", delimiters(",") stringcols(_all) clear
	ren ïcodigouasg ug_id
	ren codigoorgao ug_organ_id
	keep ug_id ug_organ_id nomeuasg
	tempfile ug_list
	save `ug_list'

	import delimited "${input_path}/Raw/comprasdados/orgaos", delimiters(",") stringcols(_all) clear
	ren ïcodigoorgao ug_organ_id
	keep ug_organ_id nomeorgao esfera
	tempfile orgao_list
	save `orgao_list'

	***** From download compras dados

	local anos 2020 2021 2022 2023 2024

	* Cria dataset temporário vazio
	clear
	tempfile compras_geral
	save `compras_geral', emptyok

	foreach ano of local anos {

		* -------- Licitações --------
		import delimited "${input_path}/Raw/comprasdados/licitacoes_2020.csv", delimiters(",") stringcols(_all) clear
		
		* few rows duplicated
		duplicates drop
		
		gen ano = `ano'
		ren uasg ug_id
		gen com_licit = 1 

		append using `compras_geral'
		save `compras_geral', replace

		* -------- Compras sem licitação --------
		import delimited "${input_path}/Raw/comprasdados/compras_sem_licitacao_`ano'.csv", delimiters(",") stringcols(_all) clear
		
		* few rows duplicated
		duplicates drop
		
		gen ano = `ano'
		ren co_uasg ug_id
		gen sem_licit = 1 
		
		append using `compras_geral'
		save `compras_geral', replace
	}

	* Carrega dataset final
	use `compras_geral', clear
		
	merge m:1 ug_id using `ug_list'
	ren _merge merge_ug
	drop if merge_ug == 2

	merge m:1 ug_organ_id using `orgao_list'
	ren _merge merge_orgao
	drop if merge_orgao == 2

	*------------------------------------------------------------*
	* Percentage of each sphere by year - LaTeX table
	*------------------------------------------------------------*

	* Recode missing
	replace esfera = "NA" if esfera == ""  

	* Categorical variable labels
	label define esfera_lbl 1 "Federal" 2 "State" 3 "Municipal" 4 "NA"
	gen esfera_cat = .
	replace esfera_cat = 1 if esfera == "F"
	replace esfera_cat = 2 if esfera == "E"
	replace esfera_cat = 3 if esfera == "M"
	replace esfera_cat = 4 if esfera == "NA"
	label values esfera_cat esfera_lbl

	* Percentage by year
	gen id = 1
	collapse (count) id, by(ano esfera_cat)
	egen total = total(id), by(ano)
	gen pct = 100 * id / total

	* Keep total obs
	preserve
	collapse (sum) N = id, by(ano)
	tempfile Nobs
	save `Nobs'
	restore

	drop id total

	* Transform to wide
	reshape wide pct, i(esfera_cat) j(ano)

	* Create matrix
	mkmat pct2020 pct2021 pct2022 pct2023 pct2024, matrix(resultados)

	* Generate a row with number of obs
	preserve
	use `Nobs', clear
	gen id = 1
	reshape wide N, i(id) j(ano)
	
	mkmat N2020 N2021 N2022 N2023 N2024, matrix(Nlinha)
	matrix rownames Nlinha = "N"
	matrix colnames Nlinha = 2020 2021 2022 2023 2024
	restore
	
	* Add to matrix
	matrix resultados = resultados \ Nlinha

	* Row names from labels
	local nomes
	levelsof esfera_cat, local(levels)
	foreach l of local levels {
		local lbl : label (esfera_cat) `l'
		local nomes `nomes' "`lbl'"
	}
	
	local nomes `nomes' "Observations"
	matrix rownames resultados = `nomes'

	* Rename columns
	matrix colnames resultados = 2020 2021 2022 2023 2024

	* Round values ​​to 2 decimal places 
	forvalues i = 1/`=rowsof(resultados)' {
		forvalues j = 1/`=colsof(resultados)' {
			matrix resultados[`i',`j'] = round(resultados[`i',`j'], 0.01)
		}
	}


	esttab matrix(resultados) using "${output_path}/Tables/uasg_esferas.tex", ///
		replace ///
		booktabs ///
		nonumber nomtitles compress nonotes  ///
		prehead("\begin{tabular}{lccccc}" "\toprule") postfoot("\bottomrule" "\end{tabular}")



