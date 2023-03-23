clear all
set more off
cd "/Users/elainewei/Dropbox/Berkeley/Spring2023/ECON 191/"

import delimited raw/Taoyuan.csv, clear encoding(Big5)

replace 移轉日期 = subinstr(移轉日期, "年", "-", .)
replace 移轉日期 = subinstr(移轉日期, "月", "", .)

split 移轉日期, parse(-) destring
ren 移轉日期1 trans_ch_year
ren 移轉日期2 trans_month


gen trans_year = 1911 + trans_ch_year 
