
clear all
***************RUN THE FILE AS IT IS . DO NOT CHANGE THE DIRECTORY
*capture current directory
*local dir `c(pwd)' or
local dir : pwd
di "`dir'"

* begin analysis
* open dataset, issue -svyset- command and describe data
use nhanes2012, clear
br sdmvpsu wtint2yr sdmvstra
svyset sdmvpsu [pweight = wtint2yr], strata(sdmvstra) singleunit(centered)

svydescribe
* 14 strata with either 2 or 3 PSUs per strata and a different number of obs 
* in each min = 140, mean = 314.7 and max = 388

* descriptives with continuous variables (including binary variables)
svy: mean ridageyr
estat sd
estat sd, var
svy: mean pad630
svy: mean hsq496
svy: mean ridageyr pad630 hsq496

* descriptives with binary variables
svy: mean female
estat sd
svy: mean dmdborn4
estat sd

svy: tab female

svy: tab female, missing count cellwidth(15) format(%15.2g)

svy: tab female dmdborn4, missing count cellwidth(15) format(%15.2g)
svy: tab female dmdborn4, col 

svy: proportion female

svy: mean ridageyr
estat effects
estat effects, deff deft meff meft
estat size
estat cv
display (.6964767/37.18519)*100

* subpops
svy: mean ridageyr
svy, subpop(female): mean ridageyr
svy, subpop(if female != 1): mean ridageyr
svy, over(female): mean ridageyr
svy, over(dmdmartl female): mean pad630

svy, subpop(female): mean pad630, over(dmdmartl dmdeduc2) 
estat size
list pad630 if female == 1 & dmdmartl == 6 & dmdeduc2 == 1

* comparing between two subpops
svy, over(female): mean hsq496
lincom [hsq496]male - [hsq496]female
display 4.589723 - 6.153479

svy, over(dmdmartl): mean hsq496
lincom [hsq496]married - [hsq496]_subpop_6
lincom [hsq496]married - [hsq496]widowed

* graphics

* need to create an weight variable with integer values to use as fw
capture drop int_wtint2yr
gen int_wtint2yr = int(wtint2yr)
histogram pad630 [fw = int_wtint2yr], bin(20)
graph export graph1.png, replace
histogram ridageyr [fw = int_wtint2yr], bin(20) normal
graph export graph2.png, replace

graph box hsq496 [pw = wtint2yr]
graph export graph3.png, replace
graph box hsq496 [pw = wtint2yr], by(female) ylabel(0(5)30)
graph export graph4.png, replace

svy, over(female): mean hsq496
estat sd

* population totals
svy: total pad630
estimates table, b(%15.2f) se(%13.2f)
estimates table, b(%15.0g) se(%12.0g)
svy: total pad630
matlist e(b), format(%15.2f)
svy, over(female): total pad630
estimates table, b(%15.2f) se(%13.2f)

* bivariate relationships
svy: mean pad630 pad675
twoway (scatter pad630 pad675) (lfit pad630 pad675 [pw = wtint2yr]), ///
title("minutes of moderate intensity work" ///
"v. minutes of moderate recreational activities")
graph export graph5.png, replace

* descriptives with categorical variables

svy: tab female
svy: proportion female
svy: mean female

svy: tab dmdmartl
svy: proportion dmdmartl
svy: tab dmdmartl, count cellwidth(12) format(%12.2g)

* the order of the options does not determine how they will be displayed
svy: tab dmdmartl, cell count obs cellwidth(12) format(%12.2g) 
svy: tab dmdmartl, count se cellwidth(15) format(%15.2g)
* only five items can be displayed at once, and ci counts as two items 
svy: tab dmdmartl, count deff deft cv cellwidth(12) format(%12.2g) 
* plot option not available with svy: prefix

* graphing single variable
capture drop male
gen male = !female
graph bar (mean) female male [pw = wtint2yr], percentages bargap(7) 
graph export graph6.png, replace

svy: mean hsq496, over(dmdmartl)
graph hbar hsq496 [pw = wtint2yr], over(dmdmartl, gap(*2)) ///
title("During the last 30 days, for about how many days" ///
"have you felt worried, tense or anxious?")
graph export graph7.png, replace

svy: mean pad630, over(dmdeduc2)
graph bar pad630 [pw = wtint2yr], over(dmdeduc2, label(angle(45))) ///
title("How much time do you spend doing" ///
"moderate-intensity activities at work on a typical day?")
graph export graph8.png, replace

svy: tab dmdmartl female, cell obs count cellwidth(12) format(%12.2g)
svy: proportion dmdmartl, over(female) 
lincom [married]male - [married]female
display .5463038 - .5164898

* OLS regression
svy: regress pad630 i.female ridageyr
margins female, vce(unconditional)

svy: regress pad630 i.female##i.hsq571 ridageyr
contrast female#hsq571
margins female#hsq571, vce(unconditional)
marginsplot
graph export graph9.png, replace

svy: regress pad630 i.female##c.pad680 
margins female, dydx(pad680) vce(unconditional)
margins female, at(pad680=(0(200)1400)) vsquish vce(unconditional)
marginsplot
graph export graph10.png, replace

* getting the difference between the male and female values
margins, dydx(female) at(pad680=(0(200)1400)) vsquish vce(unconditional)
marginsplot, yline(0)
graph export graph11.png, replace
quietly: margins, dydx(female) at(pad680=(0(200)1400)) vsquish vce(unconditional)
marginsplot, recast(line) recastci(rarea) yline(0)
graph export graph12.png, replace

* all pairwise comparisons with a categorical predictor variable
svy: regress pad630 i.dmdeduc2 ridageyr
contrast dmdeduc2
pwcompare dmdeduc2, mcompare(sidak) cformat(%3.1f) pveffects

* logistic regression
* hsd010:  General health condition:  3 = Good (the largest category)
* using hsd010 as a categorical predictor variable
svy, subpop(if ridageyr > 20): tab paq665, ///
cell obs count cellwidth(12) format(%12.2g)
svy, subpop(if ridageyr > 20): tab hsd010 paq665, ///
cell obs count cellwidth(12) format(%12.2g)

svy, subpop(if ridageyr > 20): logit paq665 ib3.hsd010 c.ridageyr
contrast hsd010

svy, subpop(if ridageyr > 20): logit paq665 ib3.hsd010##c.ridageyr
contrast hsd010#c.ridageyr
margins hsd010, subpop(if ridageyr > 20) at(ridageyr=(20(10)80)) ///
vsquish vce(unconditional)
marginsplot
graph export graph13.png, replace

* simple slopes
margins hsd010, dydx(ridageyr) subpop(if ridageyr > 20) vce(unconditional)

* checking very good is different from the others
margins rb2.hsd010, dydx(ridageyr) subpop(if ridageyr > 20) vce(unconditional)

* where are the differences between groups at different levels of age
margins, dydx(hsd010) at(ridageyr=(20(10)80)) subpop(if ridageyr > 20) vce(unconditional)
marginsplot, recast(line) recastci(rarea) yline(0)
graph export graph14.png, replace

svy, : logit paq665 ib3.hsd010##c.ridageyr
* estat gof not permitted with subpopulations
estat gof

svy: logit paq665 i.female##c.pad680 
estat gof
