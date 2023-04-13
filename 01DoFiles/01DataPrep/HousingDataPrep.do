******************************************************
* Project Title: THSR and house prices               *
* Datasets used: 房地實價登錄（2018-2022）              *
* Author: SIH-YU WEI                                 *
* Date: Mar 05, 2023                                 *
* Written in Stata 16 on a Mac                       *
******************************************************

********* SECTION 1: PREAMBLE COMMANDS 

clear all
version 16
cap log close
set more off

cd "/Users/elainewei/Dropbox/Berkeley/Spring2023/ECON 191/econ191-thsr-house-price"

********* SECTION 2: IMPORTING DATA AND CONCATENATING FILES		
		
forvalue i = 2018/2022 {
	local y`i' = 0
	
	*** looping through q1-q4
	forvalue q = 1/4 {
		import excel `"11input/01DataRaw/`i'-q`q'/G_lvr_land_A.xls"', clear ///
		sheet("不動產買賣") cellrange(A2) firstrow
		
		display `i' `q'
		
		*** renaming variables ***
		local vlist "Buildingpresentsituationpatte buildingpresentsituationpatte S T AC AD AE AF AG"
		local newnames "n_bed n_hall n_bath d_comp mainbuildingarea auxiliarybuildingarea balconyarea elevator transactionnumber"
		local n : word count `vlist'
		   
		forvalues num = 1/`n' {
			local var : word `num' of `vlist'
			local new : word `num' of `newnames'
			capture confirm variable `var'
			if !_rc {
				rename `var' `new'
			}
		}
		
		*** concatenating files ***
		if `q' != 1 {
			local r = `q'-1
			append using `y`i'_q`r'', force
		}
		display `i' `q'
		tempfile y`i'_q`q'
		save `y`i'_q`q''
	
	}
	
	if `i' != 2018 {
		local j = `i'-1
		append using `y`j'', force
	}
	tempfile y`i'
	save `y`i''

}

*** Parsing transaction year and month
destring transactionyearmonthandday, replace
gen year = floor(transactionyearmonthandday / 10000)
replace year = year + 1911
gen month = mod(floor(transactionyearmonthandday/100), 100)

*** Filtering sample

gen insample = (mainuse == "住家用") & (buildingstate == "透天厝") & ///
	(transactionsign == "房地(土地+建物)")

keep if inrange(year, 2018, 2022)

/* Writing the summary table of 
	n to a .tex file */
recode insample (0=1) (1=0), gen(notinsample)
label define lab_notinsample  0 "In Sample" 1 "Not In Sample"
label val notinsample lab_notinsample
label var notinsample "In Sample"
label var year "Year"
tabout year notinsample using "13Output/04Tables/samplenum.tex", replace ///
	bt wide(8) style(tex) format(0c 0c) h1(nil) h3(nil) ///
	topf(13Output/04Tables/top.tex) ///
	botf(13Output/04Tables/bot.tex) topstr(14cm)

********* SECTION 3: RENAMING VARS
	
local vlist "Thevillagesandtownsurbandis landsectorpositionbuildingse landshiftingtotalareasquare theusezoningorcompilesandc thenonmetropolislandusedist nonmetropolislanduse transactionyearmonthandday transactionpennumber totalfloornumber mainbuildingmaterials constructiontocompletetheyea buildingshiftingtotalarea Whetherthereismanagestheorg totalpriceNTD theunitpriceNTDsquaremet theberthcategory berthshiftingtotalareasquare theberthtotalpriceNTD thenote mainbuildingarea auxiliarybuildingarea balconyarea elevator transactionnumber"
local newnames "town address land_area urb_zoning nurb_zoning nurb_land date object_num story material completion_date building_area d_manager price unitprice parking_cat parking_area parking_price note main_area aux_area balcony_area d_elevator trans_num"
local n : word count `vlist'
   
forvalues num = 1/`n' {
	local var : word `num' of `vlist'
	local new : word `num' of `newnames'
	capture confirm variable `var'
	if !_rc {
		rename `var' `new'
	}
}
	
*** Saving sample

keep if insample
drop insample notinsample mainuse transactionsign shiftinglevel buildingstate parking*
save "11Input/02DataProcessed/sample", replace
outsheet using "11Input/02DataProcessed/sample.csv", replace comma nol
