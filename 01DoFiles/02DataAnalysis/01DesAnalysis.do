******************************************************
* Project Title: THSR and house prices               *
* Datasets used: 房地實價登錄（2018-2022）              *
* Author: SIH-YU WEI                                 *
* Date: Apr 16, 2023                                 *
* Written in Stata 16 on a Mac                       *
******************************************************

********* SECTION 1: PREAMBLE COMMANDS 
clear all
version 16
cap log close
set more off

cd "/Users/elainewei/Dropbox/Berkeley/Spring2023/ECON 191/econ191-thsr-house-price"

********* SECTION 2: IMPORTING DATA
import delimited "11Input/02DataProcessed/cleaned.csv", clear encoding(UTF8)

********* SECTION 3: PREPARING VARIABLES

*** date
tostring year, replace
tostring month, replace
gen ymonth = year + "-" + month
gen mdate = monthly(ymonth, "YM")
format mdate %tm
drop ymonth
destring year month, replace

*** material 
tab n_material, gen(material)

*** distance

global stations 四城 宜蘭 縣政中心 羅東

* changing the unit to 1 km
foreach s in $stations {
	replace dist_to`s' = dist_to`s' / 1000
}

replace min_dist = min_dist / 1000

* discrete
foreach s in $stations {
	gen within1km_`s' = (dist_to`s' < 1)
	gen within2km_`s' = (dist_to`s' < 2)
	tab within1km_`s' year
	tab within2km_`s' year
}

* zone

forvalue i = 1/5 {
	gen zone`i' = 0
}	
	
replace zone1 = (dist_to縣政中心 <= 0.5)
replace zone2 = (dist_to縣政中心 <= 1) & (dist_to縣政中心 > 0.5)
replace zone3 = (dist_to縣政中心 <= 1.5) & (dist_to縣政中心 > 1)
replace zone4 = (dist_to縣政中心 <= 2) & (dist_to縣政中心 > 1.5)
replace zone5 = (dist_to縣政中心 <= 2.5) & (dist_to縣政中心 > 2)

gen not_in_zone = 0
replace not_in_zone = 1 if zone1 + zone2 + zone3 + zone4 + zone5 == 0

replace zone1 = 1 if not_in_zone & (min_dist <= 0.5)
replace zone2 = 1 if not_in_zone & (min_dist <= 1) & (min_dist > 0.5)
replace zone3 = 1 if not_in_zone & (min_dist <= 1.5) & (min_dist > 1)
replace zone4 = 1 if not_in_zone & (min_dist <= 2) & (min_dist > 1.5)
replace zone5 = 1 if not_in_zone & (min_dist <= 2.5) & (min_dist > 2)

drop not_in_zone
gen in_zone = zone1 + zone2 + zone3 + zone4 + zone5



*** adjust for inflation

tempfile myfile
save `myfile'

import delimited "11Input/01DataRaw/cpi.csv", clear encoding(UTF8) rowrange(4:71)
keep v1 消費者物價基本分類指數
rename v1 ymonth
rename 消費者物價基本分類指數 cpi
drop if ustrlen(ymonth) <= 4 // drop year cpi, keep only monthly data
split ymonth, parse("年")
drop ymonth
rename ymonth1 year
destring year, replace
replace year = year + 1911 // convert to CE
tostring year, replace
rename ymonth2 month
replace month = usubinstr(month, "月", "", 1)
gen ymonth = year + "-" + month
gen mdate = monthly(ymonth, "YM")
format mdate %tm
keep mdate cpi

sort mdate
gen cpi_base_2018jan = cpi * 100 / cpi[1] // change base to Jan 2018
drop cpi
rename cpi_base_2018jan cpi
tempfile cpi
save `cpi'

use `myfile', clear
merge m:1 mdate using `cpi', keep(3) nogen

*** price
replace price = price * 100 / cpi
replace unitprice = unitprice * 100 /cpi
gen ln_price = log(price)

save "11Input/02DataProcessed/foranalysis.dta", replace

********* SECTION 4: SUMMARIZING

global depend ln_price
global distance dist_to縣政中心 dist_to四城 dist_to宜蘭 dist_to羅東
global zone zone1 zone2 zone3 zone4 zone5
global discrete within1km_縣政中心 within1km_四城 within1km_宜蘭 within1km_羅東
global locational $distance $discrete $zone d_urban
global struc building_area land_area percent_balcony percent_aux age n_bed n_hall n_bath n_story d_comp d_manager  d_hotspring d_leak d_reno material1
global contr d_spec_rel d_presale d_notreg

// source1: http://fmwww.bc.edu/RePEc/bocode/e/estout.old/advanced.html
// source2: http://repec.org/bocode/e/estout/hlp_estout.html#refcat
// source3: https://medium.com/the-stata-guide/the-stata-to-latex-guide-6e7ed5622856
// source4: https://www.jwe.cc/2012/03/stata-latex-tables-estout

label var ln_price "log(Price)"

label var dist_to縣政中心 "Distance to winner"
label var dist_to四城 "Distance to runner-up 1"
label var dist_to宜蘭 "Distance to runner-up 2"
label var dist_to羅東 "Distance to runner-up 3"

label var zone1 "Zone 1"
label var zone2 "Zone 2"
label var zone3 "Zone 3"
label var zone4 "Zone 4"
label var zone5 "Zone 5"

label var within1km_縣政中心 "Within 1km to winner"
label var within1km_四城 "Within 1km to runner-up 1"
label var within1km_宜蘭 "Within 1km to runner-up 2"
label var within1km_羅東 "Within 1km to runner-up 3"

label var d_urban "Is urban"

label var building_area "Total floor area ($ m^2 $)"
label var land_area "Total lot area ($ m^2 $)"
label var percent_balcony "\% floor area as balcony"
label var percent_aux "\% floor area as auxiliary"
label var age "Age"
label var n_bed "\# bedrooms"
label var n_hall "\# living rooms"
label var n_bath "\# bathrooms"
label var n_story "\# stories"
label var d_comp "Has compartment"
label var d_manager "Has manager"
label var d_hotspring "Has hotspring"
label var d_leak "Is leaking"
label var d_reno "Includes renovation fee"
label var material1 "Material" 

label var d_spec_rel "Is family transaction"
label var d_presale "Is presale house"
label var d_notreg "House is not registered"

foreach x of varlist $depend $locational $struc $contr {
  local t : var label `x'
  local t = "\hspace{0.25cm} `t'"
  lab var `x' "`t'"
}

*** summary statitics - total with detail

est clear
estpost su $depend $locational $struc $contr, detail
est store A

esttab A using "13Output/04Tables/sumtable.tex", replace ///
	cells("count mean(fmt(2)) p50(fmt(2 2 2 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0)) sd(fmt(2)) min(fmt(2 2 2 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)) max(fmt(2 2 2 2 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)) sum") ///
	collabels("Obs" "Mean" "Median" "SD" "Min" "Max" "Sum") ///
	refcat(ln_price "\emph{Dependent variable}" dist_to縣政中心 "\vspace{0.1em} \\ \emph{Locational}" building_area "\vspace{0.1em} \\ \emph{Structural}" d_spec_rel "\vspace{0.1em} \\ \emph{Contractual}", nolabel) ///
	nostar unstack nomtitle booktabs nonum noobs label f gaps

*** summary statistics - groups

global struc1 building_area land_area percent_balcony percent_aux age n_bed n_hall n_bath n_story
global struc2 d_comp d_manager d_hotspring d_leak d_reno


gen insample2km = ((within2km_四城 == 1) | (within2km_宜蘭 == 1) | (within2km_縣政中心 == 1) | (within2km_羅東 == 1))
gen tgroup = 0
replace tgroup = 1 if (within2km_縣政中心 == 1)
replace tgroup = 2 if (insample2km == 1) & (within2km_縣政中心 == 0)

est clear
eststo grp1: estpost summ $depend $struc1
eststo grp2: estpost summ $depend $struc1 if tgroup == 1
eststo grp3: estpost summ $depend $struc1 if tgroup == 2
eststo grp4: estpost summ $depend $struc1 if tgroup == 0
esttab grp* using "13Output/04Tables/sumtable_groups.tex", replace ///
	refcat(ln_price "\emph{Dependent Variable}" building_area "\emph{Structural}", nolabel) ///
	main(mean %8.3fc) aux(sd %8.3fc) nostar unstack nonumber ///
	nonote noobs label booktabs ///
	mtitle("All" "< 2 km to winner" "< 2 km to runner-ups" "Control") ///
	collabels(none) ///
	f gaps

est clear
eststo grp1: estpost summ $struc2 $contr
eststo grp2: estpost summ $struc2 $contr if tgroup == 1
eststo grp3: estpost summ $struc2 $contr if tgroup == 2
eststo grp4: estpost summ $struc2 $contr if tgroup == 0
ereturn list
esttab grp* using "13Output/04Tables/sumtable_groups.tex", append ///
	refcat(d_spec_rel "\emph{Contractual}", nolabel) ///
	cells(mean(fmt(3))) nostar unstack nonumber ///
	nomtitle nonote noobs label booktabs ///
	eqlabels(none) ///
	collabels(none) ///
	stats(N, fmt(%18.0g) labels("\midrule Observations")) ///
	f gaps plain
	

