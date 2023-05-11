******************************************************
* Project Title: THSR and house prices               *
* Datasets used: 房地實價登錄（2018-2022）              *
* Author: SIH-YU WEI                                 *
* Date: Apr 26, 2023                                 *
* Written in Stata 16 on a Mac                       *
******************************************************

********* SECTION 1: PREAMBLE COMMANDS 
clear all
version 16
cap log close
set more off

cd "/Users/elainewei/Dropbox/Berkeley/Spring2023/ECON 191/econ191-thsr-house-price"

********* SECTION 2: IMPORTING DATA
use "11Input/02DataProcessed/foranalysis.dta", clear

********* SECTION 3: GLOBALING COMMON VARS

global stations 四城 宜蘭 縣政中心 羅東

gen ln_building_area = log(building_area)
gen ln_land_area = log(land_area)

global depend ln_price
global distance dist_to四城 dist_to宜蘭 dist_to縣政中心 dist_to羅東
global zone zone1 zone2 zone3 zone4 zone5
global discrete within1km_四城 within1km_宜蘭 within1km_縣政中心 within1km_羅東
global struc ln_building_area ln_land_area percent_balcony percent_aux age n_bed n_hall n_bath n_story d_comp d_manager  d_hotspring d_leak d_reno
global contr d_spec_rel d_presale d_notreg

********* SECTION: comparing the differences between each group

gen insample2km = ((within2km_四城 == 1) | (within2km_宜蘭 == 1) | (within2km_縣政中心 == 1) | (within2km_羅東 == 1))

gen tgroup = 0
replace tgroup = 1 if (within2km_縣政中心 == 1)
replace tgroup = 2 if (insample2km == 1) & (within2km_縣政中心 == 0)

tabstat age building_area unitprice, by(tgroup) stat(mean sd min max)

********* SECTION: regression specification with unitprice

*** phase 1

gen post1 = (year>=2022 | (year==2021 & month>=2))
gen regspec1 = 1
replace regspec1 = 0 if (year>2022 | (year==2021 & month>=12))

*** specification 1
gen inter11 = post1*min_dist
lab var inter11 "$ Dist \times Post1$"

reg unitprice inter11 min_dist post1 if regspec1 == 1, r
reg unitprice inter11 min_dist post1 $contr if regspec1 == 1, r

gen building_area2 = building_area^2
reg ln_price inter11 min_dist post1 if regspec1 == 1, r
reg ln_price inter11 min_dist post1 $contr if regspec1 == 1, r
reg ln_price inter11 min_dist post1 ln_building_area age if regspec1 == 1, r
reg ln_price inter11 min_dist post1 ln_building_area age n_bath if regspec1 == 1, r
reg ln_price inter11 min_dist post1 ln_building_area age n_bath n_story if regspec1 == 1, r
reg ln_price inter11 min_dist post1 building_area building_area2 if regspec1 == 1, r

twoway scatter ln_price ln_building_area, msize(tiny)

*** phase 2

gen post2 = (year>=2022 | (year==2021 & month>=12))
gen inter2 = post2*dist_to縣政中心
lab var inter2 "$ Dist \times Post2$"

label var dist_to縣政中心 "Distance to winner"

gen regspec2 = 0
replace regspec2 = 1 if (year>2022 | (year==2021 & month>=2))

* part sample

reg unitprice inter2 dist_to縣政中心 post2 if regspec2 & insample2km

********* SECTION: regression for phase 1 with different stations

gen inter1縣政中心 = dist_to縣政中心 * post1
lab var inter1縣政中心 "$ Dist \times Post1$"

est clear
eststo: reg ln_price inter1縣政中心 dist_to縣政中心 post1 if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter1縣政中心 dist_to縣政中心 post1 $contr if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter1縣政中心 dist_to縣政中心 post1 $struc if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter1縣政中心 dist_to縣政中心 post1 $contr $struc if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab using "13Output/04Tables/phase1reg_difstation.tex", replace  ///
	keep(inter*) ///
	order(inter1縣政中心) ///
	b(4) se(4) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes noobs collabels(none) compress ///
	booktabs pa ///
	refcat(inter1縣政中心 "\emph{Winner: County Government}", nolabel) ///
	gaps f

est clear
gen inter1四城 = dist_to四城 * post1
lab var inter1四城 "$ Dist \times Post1$"
eststo: reg ln_price inter1四城 dist_to四城 post1 if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter1四城 dist_to四城 post1 $contr if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter1四城 dist_to四城 post1 $struc if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter1四城 dist_to四城 post1 $contr $struc if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab using "13Output/04Tables/phase1reg_difstation.tex", append  ///
	keep(inter*) ///
	order(inter1四城) ///
	b(4) se(4) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes noobs collabels(none) compress ///
	booktabs pa ///
	refcat(inter1四城 "\emph{Runner-up 1: Sicheng}", nolabel) ///
	gaps f plain
	
est clear
gen inter1宜蘭 = dist_to宜蘭 * post1
lab var inter1宜蘭 "$ Dist \times Post1$"
eststo: reg ln_price inter1宜蘭 dist_to宜蘭 post1 if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter1宜蘭 dist_to宜蘭 post1 $contr if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter1宜蘭 dist_to宜蘭 post1 $struc if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter1宜蘭 dist_to宜蘭 post1 $contr $struc if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab using "13Output/04Tables/phase1reg_difstation.tex", append  ///
	keep(inter*) ///
	order(inter1宜蘭) ///
	b(4) se(4) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) noobs compress ///
	booktabs pa ///
	refcat(inter1宜蘭 "\emph{Runner-up 2: Yilan City}", nolabel) ///
	gaps f plain

est clear
gen inter1羅東 = dist_to羅東 * post1
lab var inter1羅東 "$ Dist \times Post1$"
eststo: reg ln_price inter1羅東 dist_to羅東 post1 if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter1羅東 dist_to羅東 post1 $contr if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter1羅東 dist_to羅東 post1 $struc if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter1羅東 dist_to羅東 post1 $contr $struc if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab using "13Output/04Tables/phase1reg_difstation.tex", append  ///
	keep(inter*) ///
	order(inter1羅東) ///
	b(4) se(4) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) compress ///
	scalars("contractual \midrule Contractual controls" "structural Structural controls") ///
	booktabs pa ///
	refcat(inter1羅東 "\emph{Runner-up 3: Luodong}", nolabel) ///
	gaps f plain obslast

reg ln_price inter1羅東 dist_to羅東 post1 if regspec1 == 1 & within2km_羅東, r
reg ln_price inter1羅東 dist_to羅東 post1 $contr if regspec1 == 1 & within2km_羅東, r
reg ln_price inter1羅東 dist_to羅東 post1 $struc if regspec1 == 1 & within2km_羅東, r
reg ln_price inter1羅東 dist_to羅東 post1 $contr $struc if regspec1 == 1 & within2km_羅東, r
reg ln_price dist_to羅東 if regspec1 == 1 & within2km_羅東, r
	
********* SECTION: checking outliers

*** checking the spike in 2020 q2
preserve
keep if year == 2022 & month > 3 & month < 7
gen priceinthousand = floor(price / 1000)
sum priceinthousand, detail
sort priceinthousand
list in -5/L

restore

********* SECTION: checking change of characteristics in phase 1

*** area
lab var dist_to宜蘭 "Distance to Yilan"
lab var dist_to四城 "Distance to Sicheng"
lab var dist_to羅東 "Distance to Luodong"

est clear
eststo: reg ln_building_area dist_to縣政中心
eststo: reg ln_building_area inter1縣政中心 dist_to縣政中心 post1 if regspec1 == 1
eststo: reg ln_building_area dist_to宜蘭
eststo: reg ln_building_area inter1宜蘭 dist_to宜蘭 post1 if regspec1 == 1
eststo: reg ln_building_area dist_to四城
eststo: reg ln_building_area inter1四城 dist_to四城 post1 if regspec1 == 1
eststo: reg ln_building_area dist_to羅東
eststo: reg ln_building_area inter1羅東 dist_to羅東 post1 if regspec1 == 1

esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter* dist*)
esttab using "13Output/04Tables/phase1area.tex", replace  ///
	keep(inter* dist*) ///
	order(dist_to縣政中心 dist_to宜蘭 dist_to四城 dist_to羅東 inter1縣政中心 inter1宜蘭 inter1四城 inter1羅東 ) ///
	b(4) se(4) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) compress ///
	booktabs pa ///
	gaps
	
*** age	

est clear
eststo: reg age dist_to縣政中心 if regspec1 == 1
eststo: reg age inter1縣政中心 dist_to縣政中心 post1 if regspec1 == 1
eststo: reg age dist_to宜蘭 if regspec1 == 1
eststo: reg age inter1宜蘭 dist_to宜蘭 post1 if regspec1 == 1
eststo: reg age dist_to四城 if regspec1 == 1
eststo: reg age inter1四城 dist_to四城 post1 if regspec1 == 1
eststo: reg age dist_to羅東 if regspec1 == 1
eststo: reg age inter1羅東 dist_to羅東 post1 if regspec1 == 1
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter* dist*)
esttab using "13Output/04Tables/phase1age.tex", replace  ///
	keep(inter* dist*) ///
	order(dist_to縣政中心 dist_to宜蘭 dist_to四城 dist_to羅東 inter1縣政中心 inter1宜蘭 inter1四城 inter1羅東 ) ///
	b(4) se(4) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) compress ///
	booktabs pa ///
	gaps
	
*** table for struc comparison
gen inter1sw = 0
label var inter1sw"$ Dist \times Post1 $"

est clear
replace inter1sw = inter11
eststo: reg ln_building_area inter1sw min_dist post1 if regspec1 == 1
replace inter1sw = inter1縣政中心
eststo: reg ln_building_area inter1sw dist_to縣政中心 post1 if regspec1 == 1
replace inter1sw = inter1四城
eststo: reg ln_building_area inter1sw dist_to四城 post1 if regspec1 == 1
replace inter1sw = inter1宜蘭
eststo: reg ln_building_area inter1sw dist_to宜蘭 post1 if regspec1 == 1
replace inter1sw = inter1羅東
eststo: reg ln_building_area inter1sw dist_to羅東 post1 if regspec1 == 1
esttab, nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*)
esttab using "13Output/04Tables/phase1struc.tex", replace  ///
	keep(inter*) ///
	eqlabels(none) ///
	b(4) se(4) label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes noobs ///
	mtitles("Nearest" "Winner" "Runner-up 1" "Runner-up 2" "Runner-up 3") compress ///
	refcat(inter1sw "\emph{Dependent: Log floor area}", nolabel) ///
	booktabs pa ///
	gaps f

est clear
replace inter1sw = inter11
eststo: reg age inter1sw min_dist post1 if regspec1 == 1
replace inter1sw = inter1縣政中心
eststo: reg age inter1sw dist_to縣政中心 post1 if regspec1 == 1
replace inter1sw = inter1四城
eststo: reg age inter1sw dist_to四城 post1 if regspec1 == 1
replace inter1sw = inter1宜蘭
eststo: reg age inter1sw dist_to宜蘭 post1 if regspec1 == 1
replace inter1sw = inter1羅東
eststo: reg age inter1sw dist_to羅東 post1 if regspec1 == 1
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*)
esttab using "13Output/04Tables/phase1struc.tex", append  ///
	keep(inter*) ///
	b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) compress ///
	booktabs pa noobs ///
	refcat(inter1sw "\emph{Dependent: Age}", nolabel) ///
	gaps f plain
	
*** price and structures
label var ln_building_area "Log floor area"
label var ln_land_area "Log lot area"
label var percent_balcony "% floor area as balcony"
label var percent_aux "% floor area as auxiliary"
label var age "Age"
label var n_bed "# bedrooms"
label var n_hall "# living rooms"
label var n_bath "# bathrooms"
label var n_story "# stories"
label var d_comp "Has compartment"
label var d_manager "Has manager"
label var d_hotspring "Has hotspring"
label var d_leak "Is leaking"
label var d_reno "Includes renovation fee"
reg ln_price $struc if regspec1 == 1
coefplot, drop(_cons) xline(0)
graph export "13Output/03Graphs/struc_coef.png", replace
	
*** number of transaction

gen date = ym(year, month)
format date %tm
gen quarter = qofd(dofm(date))
format quarter %tq

preserve

collapse (count) price, by(tgroup quarter)
rename price number

bysort tgroup (quarter): gen num_2018q1 = number / number[1]
gen number_base_2018q1 = num_2018q1 * 100

twoway  (line number_base_2018q1 quarter if tgroup == 0, lp(solid)) ///
		(line number_base_2018q1 quarter if tgroup == 1, lp(dash)) ///
		(line number_base_2018q1 quarter if tgroup == 2, lp(shortdash)), ///
		tline(2021q1) tline(2021q4) ///
		legend(order(2 "Within 2km to winner" 3 "Within 2km to runner-ups" 1 "Controls")) ///
		xtitle("") ///
		ytitle("Number of transaction (2018 Q1 = 100)")
graph export "13Output/03Graphs/number_time.png", replace

restore

********* SECTION: correlation of age and floor area
reg ln_building_area age
gen newhouse = (age==0)
reg newhouse inter11 min_dist post1 if regspec1
probit newhouse inter11 min_dist post1 if regspec1
