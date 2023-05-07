******************************************************
* Project Title: THSR and house prices               *
* Datasets used: 房地實價登錄（2018-2022）              *
* Author: SIH-YU WEI                                 *
* Date: Apr 19, 2023                                 *
* Written in Stata 16 on a Mac                       *
******************************************************


********* SECTION 1: PREAMBLE COMMANDS 
clear all
version 16
cap log close
set more off

*** graphing specific
grstyle init
grstyle set plain, horizontal compact
grstyle set ci
grstyle set color Dark2

cd "/Users/elainewei/Dropbox/Berkeley/Spring2023/ECON 191/econ191-thsr-house-price"

********* SECTION 2: IMPORTING DATA
use "11Input/02DataProcessed/foranalysis.dta", clear


********* SECTION 3: PREPARING VARIABLES

*** preparing control variables
global stations 四城 宜蘭 縣政中心 羅東

global depend ln_price
global distance dist_to四城 dist_to宜蘭 dist_to縣政中心 dist_to羅東
global zone zone1 zone2 zone3 zone4 zone5
global discrete within1km_四城 within1km_宜蘭 within1km_縣政中心 within1km_羅東
global struc building_area land_area percent_balcony percent_aux age n_bed n_hall n_bath n_story d_urban d_comp d_manager  d_hotspring d_leak d_reno material*
global contr d_spec_rel d_presale d_notreg

*** preparing vars

gen treat = (dist_to縣政中心 < 2.5)
gen post2 = (year>=2022 | (year==2021 & month>=12))

gen insample2km = ((within2km_四城 == 1) | (within2km_宜蘭 == 1) | (within2km_縣政中心 == 1) | (within2km_羅東 == 1))

gen insample2p5km = 0
foreach s in $stations {
	replace insample2p5km = 1 if dist_to`s' < 2.5
}

gen regspec2 = 0
replace regspec2 = 1 if (year>2022 | (year==2021 & month>=2))

forvalue i = 1/5{
	gen inter_zone`i' = post2*zone`i'*treat
	label var inter_zone`i' `"Zone `i'"'
}
global inter_zone_full inter_zone1 inter_zone2 inter_zone3 inter_zone4 inter_zone5
global zone_full zone1 zone2 zone3 zone4 zone5

********* SECTION 4: ZONES

reg ln_price $inter_zone_full $zone_full treat post2 if insample2p5km & regspec2
estimates store A
reg ln_price $inter_zone_full $zone_full treat post2 $struc $contr if insample2p5km & regspec2
estimates store B

// source: https://repec.sowi.unibe.ch/stata/coefplot/getting-started.html

coefplot (A, label("Without controls")) ///
		 (B, label("With controls")), ///
		 vertical keep(inter_zone*) ///
		 ciopts(recast(rcap)) ///
		 yline(0)
		 
graph export "13Output/03Graphs/zone.png", replace

********* SECTION 5: TREAT 1 & 2

gen tgroup = 0
replace tgroup = 1 if (within2km_縣政中心 == 1)
replace tgroup = 2 if (insample2km == 1) & (within2km_縣政中心 == 0)

gen date = ym(year, month)
format date %tm
gen quarter = qofd(dofm(date))
format quarter %tq

preserve

collapse (mean) unitprice price, by(tgroup quarter)
gen ln_price = log(price)
gen unitprice_us = unitprice / 30

twoway  (line unitprice_us quarter if tgroup == 0, lp(solid)) ///
		(line unitprice_us quarter if tgroup == 1, lp(dash)) ///
		(line unitprice_us quarter if tgroup == 2, lp(shortdash)), ///
		tline(2021q1) tline(2021q4) ///
		legend(order(2 "Within 2km to winner" 3 "Within 2km to runner-ups" 1 "Controls")) ///
		xtitle("") ///
		ytitle("Price($) per unit")
graph export "13Output/03Graphs/price_time.png", replace

*** showing change rate ***

// resource: https://www.statalist.org/forums/forum/general-stata-discussion/general/1474123-changing-the-base-year-and-creating-an-index-from-that-year-in-a-time-series

bysort tgroup (quarter): gen def_2018q1 = unitprice / unitprice[1]
gen price_base_2018q1 = def_2018q1 * 100

twoway  (line price_base_2018q1 quarter if tgroup == 0, lp(solid)) ///
		(line price_base_2018q1 quarter if tgroup == 1, lp(dash)) ///
		(line price_base_2018q1 quarter if tgroup == 2, lp(shortdash)), ///
		tline(2021q1) tline(2021q4) ///
		legend(order(2 "Within 2km to winner" 3 "Within 2km to runner-ups" 1 "Controls")) ///
		ytitle("") ///
		xtitle("") 
graph export "13Output/03Graphs/price_change.png", replace


restore

********* SECTION 6: DISTANCE

// twoway scatter unitprice

