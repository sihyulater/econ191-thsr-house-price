******************************************************
* Project Title: THSR and house prices               *
* Datasets used: 房地實價登錄（2018-2022）              *
* Author: SIH-YU WEI                                 *
* Date: Apr 03, 2023                                 *
* Written in Stata 16 on a Mac                       *
******************************************************

********* SECTION 1: PREAMBLE COMMANDS 
clear all
version 16
cap log close
set more off

cd "/Users/elainewei/Dropbox/Berkeley/Spring2023/ECON 191/econ191-thsr-house-price"

********* SECTION 2: IMPORTING DATA
import delimited "11Input/02DataProcessed/geocoded_sample.csv", clear encoding(UTF8)

********* SECTION 3: PREPARING VARS
drop v1
*** encoding story
gen n_story = 0
local vallist "一層 二層 三層 四層 五層"
local n : word count `vallist'
forvalues num = 1/5 {
	local var : word `num' of `vallist'
	replace n_story = `num' if story == `"`var'"' 
}
*** encoding material 
gen n_material = 0
local brick "加強磚造 磚造 加強磚造、木石磚造（磚石造） 木石磚造 木石磚造（磚石造） 磚石造 石造 木造 土造 土竹造（土磚混合造） 土磚石混合造"
local rc "鋼筋混凝土造（ＲＣ） 鋼筋混凝土（ＲＣ） ＲＣ造 鋼筋混凝土造 鋼筋混凝土  鋼筋混凝土（ＲＣ）、木構造 鋼骨鋼筋混凝土造 鋼筋混凝土、鋼骨造 鋼骨造 鋼造"
local rc_brick "鋼筋混凝土造、加強磚造 鋼筋混凝土造及鋼筋混凝土加強磚造 鋼筋混凝土造鋼筋混凝土加強磚造 鋼筋混凝土加強磚造 鋼筋混凝土加強磚造、鋼架造 鐵筋加強磚造、ＲＣ造 鐵筋加強磚造 ＲＣ加強磚造 鋼筋混凝土加強磚造及鋼筋混凝土造 鋼筋混凝土加強磚造﹒鋼筋混凝土造 鐵筋加強磚造及木造"
local iron "鋼鐵造、鋼架造有牆 鋼鐵有牆造"
foreach name in `brick'{
	dis `name'
	replace n_material = 1 if material == `"`name'"'
}
