******************************************************
* Project Title: THSR and house prices               *
* Datasets used: 房地實價登錄（2018-2022）              *
* Author: SIH-YU WEI                                 *
* Date: Apr 17, 2023                                 *
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

********* SECTION 3: PREPARING FOR VARIABLES

*** preparing control variables

global stations 四城 宜蘭 縣政中心 羅東

global depend ln_price
global distance dist_to四城 dist_to宜蘭 dist_to縣政中心 dist_to羅東
global zone zone1 zone2 zone3 zone4 zone5
global discrete within1km_四城 within1km_宜蘭 within1km_縣政中心 within1km_羅東
global struc building_area land_area percent_balcony percent_aux age n_bed n_hall n_bath n_story d_urban d_comp d_manager  d_hotspring d_leak d_reno material*
global contr d_spec_rel d_presale d_notreg


********* SECTION 4: REGRESSION FOR PHASE 1

// source: https://medium.com/the-stata-guide/the-stata-to-latex-guide-6e7ed5622856

gen post1 = (year>=2022 | (year==2021 & month>=2))
gen regspec1 = 1
replace regspec1 = 0 if (year>2022 | (year==2021 & month>=12))

*** specification 1
gen inter11 = post1*closest_dist
lab var inter11 "$ Dist \times Post1$"

est clear
eststo: reg ln_price inter11 closest_dist post1 if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter11 closest_dist post1 $contr if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter11 closest_dist post1 $struc if regspec1 == 1, r
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter11 closest_dist post1 $struc $contr if regspec1 == 1, r
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*) ///
	scalars("contractual Contractual controls" "structural Structural controls")
esttab using "13Output/04Tables/phase1reg.tex", replace  ///
	keep(inter*) ///
	b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) compress ///
	booktabs pa ///
	refcat(inter11 "\textbf{Panel A: Distance}", nolabel) ///
	gaps f noobs

*** specification 2
gen treat1km = ((within1km_四城 == 1) | (within1km_宜蘭 == 1) | (within1km_縣政中心 == 1) | (within1km_羅東 == 1))
gen inter1km = treat1km*post1
lab var inter1km "$ 1km \times Post1$"

est clear
eststo: reg ln_price inter1km treat1km post1 if regspec1 == 1
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter1km treat1km post1 $contr if regspec1 == 1
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter1km treat1km post1 $struc if regspec1 == 1
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter1km treat1km post1 $struc $contr if regspec1 == 1
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*) ///
	scalars("contractual Contractual controls" "structural Structural controls")
esttab using "13Output/04Tables/phase1reg.tex", append  ///
	keep(inter*) ///
	b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) compress ///
	booktabs pa ///
	refcat(inter1km "\vspace{0.1em} \\ \textbf{Panel B: Within 1km dummy}", nolabel) ///
	gaps f noobs plain

*** specification 3
gen treat2km = ((within2km_四城 == 1) | (within2km_宜蘭 == 1) | (within2km_縣政中心 == 1) | (within2km_羅東 == 1))
gen inter2km = treat1km*post1
lab var inter2km "$ 2km \times Post1$"

est clear
eststo: reg ln_price inter2km treat2km post1 if regspec1 == 1
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter2km treat2km post1 $contr if regspec1 == 1
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter2km treat2km post1 $struc if regspec1 == 1
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter2km treat2km post1 $struc $contr if regspec1 == 1
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*) ///
	scalars("contractual Contractual controls" "structural Structural controls")
esttab using "13Output/04Tables/phase1reg.tex", append  ///
	keep(inter*) ///
	b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) compress ///
	booktabs ///
	scalars("contractual \midrule Contractual controls" "structural Structural controls") sfmt(0) ///
	refcat(inter2km "\vspace{0.1em} \\ \textbf{Panel C: Within 2km dummy}", nolabel) ///
	pa gaps f plain obslast
	

********* SECTION 5: REGRESSION FOR PHASE 2

gen post2 = (year>=2022 | (year==2021 & month>=12))
gen inter2 = post2*dist_to縣政中心
lab var inter2 "$ Dist \times Post2$"

label var dist_to縣政中心 "Distance to winner"

gen regspec2 = 0
replace regspec2 = 1 if (year>2022 | (year==2021 & month>=2))

*** specification 1

* full sample
est clear
eststo: reg ln_price inter2 dist_to縣政中心 post2 if regspec2 == 1
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter2 dist_to縣政中心 post2 $contr if regspec2 == 1
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter2 dist_to縣政中心 post2 $struc if regspec2 == 1
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter2 dist_to縣政中心 post2 $struc $contr if regspec2 == 1
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*) ///
	scalars("contractual Contractual controls" "structural Structural controls")

* part sample

gen insample2km = ((within2km_四城 == 1) | (within2km_宜蘭 == 1) | (within2km_縣政中心 == 1) | (within2km_羅東 == 1))

eststo: reg ln_price inter2 dist_to縣政中心 post2 if regspec2 & insample2km
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter2 dist_to縣政中心 post2 $contr if regspec2 & insample2km
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter2 dist_to縣政中心 post2 $struc if regspec2 & insample2km
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter2 dist_to縣政中心 post2 $struc $contr if regspec2 & insample2km
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*) ///
	scalars("contractual Contractual controls" "structural Structural controls")
esttab using "13Output/04Tables/phase2-spec1.tex", replace  ///
	keep(inter*) ///
	b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) ///
	booktabs ///
	scalars("contractual \midrule Contractual controls" "structural Structural controls") sfmt(0) ///
	mgroups("Full sample" "Restricted sample", pattern(1 0 0 0 1 0 0 0) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) alignment(D{.}{.}{-1}) ///
	pa gaps f


*** specification 2
gen treat = (dist_to縣政中心 < 2.5)
forvalue i = 1/5{
	gen inter_zone`i' = post2*zone`i'*treat
}

* full sample

global inter_zone_full inter_zone1 inter_zone2 inter_zone3 inter_zone4 inter_zone5
global zone_full zone1 zone2 zone3 zone4 zone5

est clear
eststo: reg ln_price $inter_zone_full $zone_full treat post2 if regspec2
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price $inter_zone_full $zone_full treat post2 $contr if regspec2
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price $inter_zone_full $zone_full treat post2 $struc if regspec2
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price $inter_zone_full $zone_full treat post2 $struc $contr if regspec2
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"


global inter_zone_d inter_zone1 inter_zone2 inter_zone3 inter_zone4
global zone_d zone1 zone2 zone3 zone4

tab insample2km regspec2

gen insample2p5km = 0
foreach s in $stations {
	replace insample2p5km = 1 if dist_to`s' < 2.5
}

eststo: reg ln_price $inter_zone_full $zone_full treat post2 if insample2p5km & regspec2
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price $inter_zone_full $zone_full treat post2 $contr if insample2p5km & regspec2
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price $inter_zone_full $zone_full treat post2 $struc if insample2p5km & regspec2
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price $inter_zone_full $zone_full treat post2 $struc $contr if insample2p5km & regspec2

	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*) ///
	scalars("contractual Contractual controls" "structrural Structrural controls")
esttab using "13Output/04Tables/phase2-spec2.tex", replace  ///
	keep(inter*) ///
	b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) ///
	booktabs ///
	mgroups("Full sample" "Restricted sample", pattern(1 0 0 0 1 0 0 0) ///
	prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) alignment(D{.}{.}{-1}) ///
	scalars("contractual \midrule Contractual controls" "structural Structural controls") sfmt(0) ///
	pa gaps f



*** specification 3
foreach s in $stations{
	tab within1km_`s' if regspec2
	tab within2km_`s' if regspec2
}

gen treat23 = within2km_縣政中心
gen inter23 = treat23 * post2
lab var inter23 "$ Dist \times Post2$"

est clear
eststo: reg ln_price inter23 treat23 post2 if regspec2 & insample2km
	estadd local  contractual  "No"
	estadd local  structural  "No"
eststo: reg ln_price inter23 treat23 post2 $contr if regspec2 & insample2km
	estadd local  contractual  "Yes"
	estadd local  structural  "No"
eststo: reg ln_price inter23 treat23 post2 $struc if regspec2 & insample2km
	estadd local  contractual  "No"
	estadd local  structural  "Yes"
eststo: reg ln_price inter23 treat23 post2 $contr $struc if regspec2 & insample2km
	estadd local  contractual  "Yes"
	estadd local  structural  "Yes"
esttab, b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	keep(inter*) ///
	scalars("contractual Contractual controls" "structrural Structrural controls")
esttab using "13Output/04Tables/phase2-spec3.tex", replace  ///
	keep(inter*) ///
	b(3) se(3) nomtitle label star(* 0.10 ** 0.05 *** 0.01) ///
	nonotes collabels(none) ///
	booktabs ///
	scalars("contractual \midrule Contractual controls" "structural Structural controls") sfmt(0) ///
	pa gaps f
