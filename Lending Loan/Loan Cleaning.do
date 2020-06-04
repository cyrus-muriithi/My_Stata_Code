********************************************************************************
* Author: Cyrus Herder *********************************************************
* Date: May 2020 ***************************************************************
* Reason: Exploring lending_club_loans *****************************************
********************************************************************************
********************************************************************************
clear all
*https://rstudio-pubs-static.s3.amazonaws.com/208332_c1bab2ab0b66488a89f387e00aaf01e3.html
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
{
* Loading the data
cd "C:\Users\ch\Desktop\Random Programming\Lending_Loan"

import delimited "lending_club_loans.csv"
drop if id =="Loans that do not meet the credit policy" | id==""

desc
}
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
{
* Cleaning variables
quietly ds, has(type string)
foreach var in `r(varlist)' {
quietly count if `var'==""
loc size = 100 * r(N) / _N
di  `size'
        if `size'==100 {
            di "`var' : " _column(20) string(`size' ,"%5.1f") "%" 
            drop `var'
        }
}
* Double
quietly ds, has(type double)
foreach var in `r(varlist)' {
quietly count if `var'==.
loc size = 100 * r(N) / _N
di  `size'
        if `size'==100 {
            di "`var' : " _column(20) string(`size' ,"%5.1f") "%" 
            drop `var'
        }
}
* Byte
quietly ds, has(type byte)
foreach var in `r(varlist)' {
quietly count if `var'==.
loc size = 100 * r(N) / _N
di  `size'

        if `size'==100 {
            di "`var' : " _column(20) string(`size' ,"%5.1f") "%" 
            drop `var'
        }
}

* Float
quietly ds, has(type float)
foreach var in `r(varlist)' {
quietly count if `var'==.
loc size = 100 * r(N) / _N
di  `size'

        if `size'==100 {
            di "`var' : " _column(20) string(`size' ,"%5.1f") "%" 
            drop `var'
        }
}

* Int
quietly ds, has(type int)
foreach var in `r(varlist)' {
quietly count if `var'==.
loc size = 100 * r(N) / _N
di  `size'

        if `size'==100 {
            di "`var' : " _column(20) string(`size' ,"%5.1f") "%" 
            drop `var'
        }
}
}
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
{
* Feature engineering
destring id, replace
isid id
isid member_id
drop url

foreach v in int_rate revol_util {
    replace `v' = subinstr(`v', "%", "",.) 
	destring `v', replace
}


gen str award_status = cond(loan_amnt==funded_amnt,"Same", ///
		cond(loan_amnt>funded_amnt,"Less", ///
		cond(loan_amnt<funded_amnt,"More","")))


loc devars term grade sub_grade emp_title emp_length home_ownership verification_status loan_status pymnt_plan purpose award_status
foreach var of varlist  `devars'{
    encode `var', gen(_n`var')
	drop `var'
}

foreach v of varlist _n*{
	loc remove = substr("`v'", 1, 2)
	local new : subinstr local v "`remove'" ""
    ren `v' `new'
}
}
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
{
* Descriptives

* Loan amount will be a key outcome , therefore worth playing with.
* skewed, not normally distributed
hist loan_amnt, percent normal //addlabels ylabel(,grid) xlabel(12(2)42)

gen loan_amnt_log = log(loan_amnt)
quietly hist loan_amnt_log
graph box  loan_amnt_log


* Correlation factor of loan amount and funded_amnt
corr loan_amnt funded_amnt

* Ttest of loan amount by loan term and ward status
ttest loan_amnt, by(term) //the difference is significant between 36 and 60 months loan term
ttest loan_amnt, by(award_status) 


* Association of installment and loan amount 
corr loan_amnt installment
}
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
{
* Modelling
graph twoway (lfit loan_amnt installment) (scatter loan_amnt installment) 
quietly graph twoway scatter loan_amnt installment , ///
                title("Installment and loan amount") ///
                subtitle("Relationship") ///
                note("1") ///
                caption("Source:  Loan Club") ///
                scheme(economist)
				
*Annual income vs loan amount
corr loan_amnt annual_inc
quietly scatter loan_amnt annual_inc, ///
                title("Annual income and loan amount") ///
                subtitle("Relationship") ///
                note("1") ///
                caption("Source:  Loan Club") ///
                scheme(economist)
				
graph twoway (lfitci loan_amnt annual_inc) (scatter loan_amnt annual_inc)	if annual_inc<2000000	

* Interest rate and loan amount
corr loan_amnt int_rate
graph twoway (lfitci loan_amnt int_rate) (scatter loan_amnt int_rate)


* What factors are more likely to affect the loan amount being sought
quietly reg loan_amnt installment annual_inc open_acc pub_rec revol_util total_acc int_rate ///
	i.term i.grade i.emp_length i.home_ownership i.verification_status i.loan_status i.purpose 

* Binary of categories	
quietly tab term, gen(term)
quietly tab grade, gen(grade)
quietly tab emp_length, gen(emp_length)
quietly tab home_ownership, gen(home_ownership)
quietly tab verification_status, gen(verification_status)
quietly tab loan_status, gen(loan_status)
quietly tab  purpose, gen( purpose)

*Modelling with binaries	
quietly reg loan_amnt installment annual_inc open_acc pub_rec revol_util total_acc int_rate ///
		i.term ///
		grade1 grade2 grade3 grade4 grade5 grade6  ///
		emp_length1 emp_length2 emp_length3 emp_length4 emp_length5 emp_length6 emp_length7 emp_length8 emp_length9 emp_length10 emp_length11 ///
		home_ownership1 home_ownership2 home_ownership3 home_ownership4 ///
		verification_status1 verification_status2 ///
		loan_status1 loan_status2 loan_status3 loan_status4 loan_status5 loan_status6 loan_status7 loan_status8  ///
		purpose1 purpose2 purpose3 purpose4 purpose5 purpose6 purpose7 purpose8 purpose9 purpose10 purpose11 purpose12 purpose13 

* Simplified model 1
quietly reg loan_amnt installment annual_inc open_acc pub_rec revol_util total_acc int_rate ///
		i.term ///	
		grade2 grade3 grade5 grade6 ///
		emp_length1 emp_length2 emp_length3 emp_length4 emp_length5 emp_length7 ///
		home_ownership1 home_ownership3 ///
		verification_status1 verification_status2 ///
		purpose1 purpose2 purpose3 purpose4 purpose5 purpose12

* Simplified model 2
quietly reg loan_amnt installment annual_inc open_acc pub_rec revol_util total_acc int_rate ///
		i.term ///	
		grade2 grade3 grade5 grade6 ///
		emp_length2 ///
		home_ownership1 home_ownership3 ///
		verification_status1 verification_status2 ///
		purpose1 purpose2 purpose3 purpose4 purpose12 , robust
		
		
* Labelling of final modelling variables
ren (grade2 grade3 grade5 grade6) (gradeB gradeC gradeE gradeF)	
ren (emp_length2)	(emp_10_years_and_above)
ren (home_ownership1) (Mortgage)
ren (verification_status1 verification_status2) (NotVerified SourceVerified)
ren (purpose1 purpose2 purpose3 purpose4 purpose12) (Car CreditCard DebtConsolidation Educational SmallBusiness)

* Final Models
reg loan_amnt installment annual_inc pub_rec revol_util total_acc int_rate ///
		i.term ///
		gradeB gradeC gradeE gradeF ///
		emp_10_years_and_above ///
		Mortgage ///
		NotVerified SourceVerified ///
		Car CreditCard DebtConsolidation Educational SmallBusiness, robust nocons
}		
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
{
* What are levers to getting higher loan amount
/*
1. Targeting higher loan repayment installment
2. Increasing Annual income
3. Increasing total number of credit lines currently in the borrower's credit file
4. Targeting higher loan terms of 60 months
5. Loan grade B and C
6. Being employed for 10 years and above
7. Borrowing for Mortage purpose
8. Borrowing for Credit Card purpose
9. Borrowing for Debt Consolidation
10. Borrowing for Educational purpose1
11. Borrowing for SMEs especially small businesses
*/

* What are the barriers that can reduce the amount of loan being borrowed
/*
1. Increasing number of derogatory public records reduces your loan amount
2. Increasing Revolving line utilization rate, or the amount of credit the borrower is using relative to all available revolving credit reduces your loan amount
3. Increasing intestest rate reduces the loan amount
4. Being in Grade E and F reduces your loan amount
5. Verification status (Not verified and Source Verified) reduces likelihood of geeting higher loan amount
6. Borrowing loan for purposes of getting a Car reduces your loan amount
*/	
}
*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
{
*Saving modelling datasets
preserve

keep loan_amnt installment annual_inc pub_rec revol_util total_acc int_rate ///
		term ///
		gradeB gradeC gradeE gradeF ///
		emp_10_years_and_above ///
		Mortgage ///
		NotVerified SourceVerified ///
		Car CreditCard DebtConsolidation Educational SmallBusiness
		
corr loan_amnt int_rate installment annual_inc pub_rec revol_util total_acc
pwcorr loan_amnt int_rate installment annual_inc pub_rec revol_util total_acc


save LoanClubModel.dta, replace
restore
}

* Random Forest datasets
drop application_type emp_title issue_d desc title zip_code addr_state earliest_cr_line mths_since_last_record initial_list_status last_pymnt_d next_pymnt_d last_credit_pull_d	grade sub_grade emp_length home_ownership verification_status loan_status pymnt_plan purpose award_status loan_amnt_log	

corr loan_amnt funded_amnt funded_amnt_inv int_rate installment annual_inc dti delinq_2yrs fico_range_low fico_range_high inq_last_6mths mths_since_last_delinq open_acc pub_rec revol_bal revol_util total_acc out_prncp out_prncp_inv total_pymnt total_pymnt_inv total_rec_prncp total_rec_int total_rec_late_fee recoveries collection_recovery_fee last_pymnt_amnt last_fico_range_high last_fico_range_low

export delimited Randomforest.csv, replace