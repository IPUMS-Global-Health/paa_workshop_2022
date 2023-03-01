clear
cd "Z:\pma\admin\presentations\workshop2022"

use workshop_2022.dta

tab resultfq_2 resultfq_1, miss
drop *_3 *_4

//Dropping women who did not complete a survey in both surveys
keep if resultfq_1 == 1
keep if resultfq_2 == 1
//Dropping women who were not part of the de facto population
keep if (resident_1 == 11 | resident_1 == 22) & (resident_2 == 11 | resident_2 == 22)


/////Data visualization
gen category = .
replace category = 1 if cp_1 == 0 & cp_2 == 0
replace category = 2 if cp_1 == 1 & cp_2 == 1
replace category = 3 if cp_1 == 0 & cp_2 == 1
replace category = 4 if cp_1 == 1 & cp_2 == 0

//Non-users were not using a method at the time of both of their interviews
//Users were using a method at the time of both of their interviews
label define categorical 1 "Non-user" 2 "User" 3 "Adopted FP" 4 "Discontinued FP" 
label values category categorical

//Bar graph 
tab category, gen(cat_)
//First graph uses counts of interviewed women
graph bar (sum) cat_1-cat_4, over(country) legend(label(1 "Non-user") label(2 "User") label(3 "Adopted FP") label(4 "Discontinued FP"))
//The second graph uses proportions, so the visualization isn't biased by a difference in sample sizes
graph bar cat_1-cat_4, over(country) legend(label(1 "Non-user") label(2 "User") label(3 "Adopted FP") label(4 "Discontinued FP"))

/////Data Analysis
////Rename outcome variable
rename cat_3 adoption
rename cat_4 discontinue
///Explanatory variables
tab cvincomeloss_2, miss

////use hhincomelossamt to understand who did not lose income in cvincomeloss
tab cvincomeloss_2 hhincomelossamt_2
replace cvincomeloss_2 = 0 if hhincomelossamt_2 == 1
//look at the other explanatory variable
tab country covidconcern_2, row


////replace NIU to missing
forvalues i = 1/2 {
	foreach var in age marstat educattgen cvincomeloss covidconcern hcaccess hhincomelossamt wealtht cp {
		replace `var'_`i' = . if `var'_`i' > 90
	}
}

//Establishing the survey weight settings
svyset [pw=panelweight], psu(eaid_2) strata(strata_2)

//Creating an age category recode
recode age_2 (15/24=1) (25/34=2) (35/49=3), gen(age_rec)
label define agerecode 1 "15-24" 2 "25-34" 3 "35-49"
label values age_rec agerecode


//Logistic regressions

svy: logit adoption i.age_rec urban i.wealtht_2 i.educattgen_2 cvincomeloss_2 i.covidconcern_2 if country == 1 , or
svy: logit adoption i.age_rec urban i.wealtht_2 i.educattgen_2 cvincomeloss_2 i.covidconcern_2 if country == 7 , or

svy: logit discontinue i.age_rec urban i.wealtht_2 i.educattgen_2 cvincomeloss_2 i.covidconcern_2 if country == 1 , or
svy: logit discontinue i.age_rec urban i.wealtht_2 i.educattgen_2 cvincomeloss_2 i.covidconcern_2 if country == 7 , or

