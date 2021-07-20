* SM 616 Workshop 14 US Census PDB exercise
version 17

* (i) input arguments
args above_black above_hisp p1 p2 target_n
if "`above_black'" == "" {
  local above_black 40
  local above_hisp  40
}
if "`p1'" == "" {
  local p1 0.2
  local p2 0.2
}
local p3 = 1 - `p1' - `p2'
assert inrange(`p1', 0, 1) & inrange(`p2', 0, 1) & inrange(`p3', 0, 1)

if "`target_n'" == "" local target_n 2500

* (ii) put stuff into a standalone frame
frame change default
cap frame pdb: clear
cap frame drop pdb
frame create pdb
frame change pdb

* (ii.a) load the PDB CT data... prepared earlier in R
import delimited using PDB/pdb2021trv3_ct.csv, clear
destring low_response_score , replace force
drop if mi(low_response_score)


* (iii) intermediate variables

gen byte strata3 = .
replace strata3 = 1 if mi(strata3) & pct_nh_blk_alone_acs_15_19 > `above_black'
replace strata3 = 2 if mi(strata3) & pct_hispanic_acs_15_19 > `above_hisp'
replace strata3 = 3 if mi(strata3)

lab def strata3_lbl 1 "High Black/AA density" 2 "High Hispanic density" 3 "Mostly NH White"
lab var strata3 strata3_lbl

egen total_pop3 = sum(tot_population_acs_15_19), by(strata3)
egen black_pop3 = sum(nh_blk_alone_acs_15_19),   by(strata3)
egen hisp_pop3  = sum(hispanic_acs_15_19),       by(strata3)
egen _tag3      = tag(strata3)

egen tracts3    = count(gidtr),                  by(strata3)
gen  rr3 = .
forvalues k=1/3 {
  sum low_response_score [aw=tot_population_acs_15_19] if strata3 == `k'
  replace rr3 = 1 - r(mean)/100 if strata3==`k'
}

* (iv) the first pass at the sample size
gen n1_field = .
forvalues k=1/3 {
  replace n1_field = 1000*`p`k'' if strata3==`k' & _tag3
}
gen n1_total = n1_field * rr3

* (v) the second pass at the sample size
sum n1_total if _tag3
gen n2_field = n1_field * `target_n'/r(sum)
gen n2_resp  = n2_field * rr3 if _tag3
* the pct variables are on the scale of 0 to 100
gen n2_black = n2_field * rr3 * pct_nh_blk_alone_acs_15_19 / 100
gen n2_hisp  = n2_field * rr3 * pct_hispanic_acs_15_19 / 100

total n2*, coeflegend
local n2_black = _b[n2_black]
local n2_hisp  = _b[n2_hisp]

* (vi) weights and deff
gen weight  = total_pop3 / n2_resp
gen weight2 = weight*weight
gen _one    = 1

list strata3 *_pop3 tracts3 n2* weight if _tag3

total weight weight2 _one [iw=n2_resp]
nlcom _b[_one]*_b[weight2]/(_b[weight]*_b[weight])
local deff = el(r(b),1,1)

* this can stay in memory as r(b)

* (x) report the results
di _n ///
  "{txt}Input parameters:" _n "   above_black = {res}`above_black'" _n ///
  "{txt}   above_hisp  = {res}`above_hisp'" _n ///
  "{txt}   prop stratum 1 = {res}`p1'" _n "{txt}   prop stratum 2 = {res}`p2'" _n ///
  "{txt}Design outcomes:" _n "   AA/Black completes = {res}" round(`n2_black', 0.1) _n ///
  "{txt}   Hispanic completes = {res}" round(`n2_hisp', 0.1) _n ///
  "{txt}   UWE DEFF = {res}" round(`deff', 0.0001) as text
  
exit

Some results:

do SM616-2021-Census-PDB-solution-3strata.do 40 40 0.487 0.063 -> DEFF = 1.683
do SM616-2021-Census-PDB-solution-3strata.do 30 30 0.613 0.1   -> DEFF = 2.076 (too many Hisp)
do SM616-2021-Census-PDB-solution-3strata.do 30 50 0.61 0.04   -> DEFF = 2.000
do SM616-2021-Census-PDB-solution-3strata.do 50 30 0.367 0.194 -> DEFF = 1.506 (only 25 black tracts)
do SM616-2021-Census-PDB-solution-3strata.do 50 50 0.362 0.199 -> DEFF = 1.740 (only 25 black tracts)
do SM616-2021-Census-PDB-solution-3strata.do 45 35 0.425 0.10  -> DEFF = 1.546 (too many Hisp)
do SM616-2021-Census-PDB-solution-3strata.do 45 45 0.424 0.063 -> DEFF = 1.542 (too many Hisp)
do SM616-2021-Census-PDB-solution-3strata.do 45 60 0.387 0.055 -> DEFF = 1.502 (31 tracts in each special stratum)
do SM616-2021-Census-PDB-solution-3strata.do 45 55 0.388 0.055 -> DEFF = 1.482
