* (i) load the PDB CT data... prepared earlier in R
import delimited using PDB/pdb2021trv3_ct.csv, clear
destring low_response_score , replace force
drop if mi(low_response_score)

* (ii) intermediate variables
gen pct_minority = (pct_nh_blk_alone_acs_15_19 + pct_hispanic_acs_15_19)/100
gen byte strata2 = cond(pct_minority > 0.5, 1, 2)

* (iii) create a two-line stratum-level summary data set
collapse ///
  (rawsum) pop = tot_population_acs_15_19 /// total stratum population
  (rawsum) black = nh_blk_alone_acs_15_19 /// Black population
  (rawsum) hisp  = hispanic_acs_15_19     /// Hispanic population
  (count)  n_tracts = gidtr               /// number of tracts
  (mean)   lrs = low_response_score       /// weighted mean of the low_response_score variable
  [aw = tot_population_acs_15_19]         /// weights for the computation of the weighted mean
  , by(strata2)

gen rr = 1 - lrs/100

* (iv) sample allocation -- modify these numbers to obtain the sample sizes required
gen n_field = .
replace n_field = 2115 if strata2 == 1
replace n_field = 1229 if strata2 == 2

gen n_total = n_field * rr
gen n_black = n_total * black / pop
gen n_hisp  = n_total * hisp / pop

list strata2 n_*

* (iv.a) what are the total sample sizes? ignore the standard errors
total n_*

* (v) unequal weighting design effects
gen weight = pop / n_total
gen weight2 = weight * weight
gen _one = 1

total weight weight2 _one [iw=n_total]
nlcom deff: _b[_one]*_b[weight2]/(_b[weight]*_b[weight])

* all done

exit
