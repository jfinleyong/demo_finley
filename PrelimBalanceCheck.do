*PURPOSE: This do-file runs balance tests for the updated Ignitia evaluation sample using data from the original surveys (i.e., GSPS, GUP, and EP)
*CONTACT: Andre Nickow, a-nickow@kellogg.northwestern.edu
*LAST UPDATED: May 31, 2022


********************************************************************************
*OPENING COMMANDS
********************************************************************************
clear all
set more off


********************************************************************************
*DIRECTORY GLOBALS
********************************************************************************
gl ignitia_samp "X:\Box\Ignitia\04_Research Design\04 Randomization & Sampling\SummaryStatistics_Sampling approach"
gl outputs "X:\Box\Ignitia\08_Analysis & Results\01 Data Analysis\Outputs"


********************************************************************************
*ACCESS DATA AND RUN BALANCE CHECKS
********************************************************************************
use "${ignitia_samp}\hhsamp_final"


eststo clear
loc list hhsize hh_numfrmrs hh_head_fem hh_fem anychem anyfert fd_dz2 dz2 fdconsumpcedis tot_plot_size 
foreach var of local list {
	eststo `var' : reg `var' ibn.treatment i.survey_n, nocons cl(village)
	testparm 0.treatment 1.treatment 2.treatment, equal 
		estadd scalar pval = r(p)
	label variable `var' "`=strproper("`: variable label `var''")'"
}


label variable hh_numfrmrs "Number of Farmers in the Household"
label variable hh_head_fem "Gender of Household Head is Female (0/1)"
label variable hh_fem "Ratio of Woman in the Household"
label variable anychem "Household Uses Fertilizer Herbicide or Insecticide (0/1)"
label variable anyfert "Household Uses Fertilizer (0/1)"
label variable fd_dz2 "Food Expenditure per Adult-Equivalence Capita"
label variable dz2 "Adult-Equivalence"
label variable fdconsumpcedis "Food Consumption in Cedis"
label variable tot_plot_size "Total Plot Size (Acres)"

esttab `var' using "${outputs}/balance_table.csv",				///
			 b(%9.2fc) se(%9.2fc) 							///
			 drop(*survey_n) label							///
			 coef(0.treatment "Control"   		            ///
			      1.treatment "Weather Forecasting (T1)" 		///
				  2.treatment "Climate Smart Messages (T2)") 					///
				  stats(pval, l("P-value"))					///
			 nogaps nostar parentheses nonum 	///
			 title("Household Level Balance at Baseline")				///
			 replace

			 
********************************************************************************
*Num of HHs BY DISTRICT AND TREATMENT STATUS		 
********************************************************************************
clear all
use "${ignitia_samp}\hhsamp_final"

bysort district: gen numhh = _N		



bysort district: egen numhh_dc = count(numhh) if treatment == 0
bysort district: egen numhh_dt1 = count(numhh) if treatment == 1
bysort district: egen numhh_dt2 = count(numhh) if treatment == 2
bysort district: egen numhh_d = count(numhh)

collapse (mean) numhh_dc numhh_dt1 numhh_dt2 numhh_d, by(region district)

foreach var in numhh_dc numhh_dt1 numhh_dt2 	{
	replace `var' = 0 if mi(`var')
}

export excel using "${outputs}\nHH_by_district.xlsx", firstrow(varl) replace


********************************************************************************
*Num of Vills BY DISTRICT AND TREATMENT STATUS		 
********************************************************************************
clear all
use "${ignitia_samp}\hhsamp_final"

collapse treatment, by(region district village)

bysort district: gen numvil = _N
bysort district: egen numv_c = count(numvil) if treatment == 0
bysort district: egen numv_t1 = count(numvil) if treatment == 1
bysort district: egen numv_t2 = count(numvil) if treatment == 2
bysort district: egen numv_d = count(numvil) 

collapse (mean) numv_c numv_t1 numv_t2 numv_d, by(region district)

export excel using "${outputs}\nVill_by_district.xlsx", firstrow(varl) replace

********************************************************************************
*Num of HHs BY VILLAGE AND TREATMENT STATUS		 
********************************************************************************
clear all
use "${ignitia_samp}\hhsamp_final"

bysort treatment region district village survey: gen numhhvill = _N	
bysort treatment region district village survey: egen numhh_v = count(numhhvill) 


collapse (mean) numhh_v, by(treatment region district village survey)

order treatment region district village  numhh_v survey

export excel using "${outputs}\nHH_by_vill.xlsx", firstrow(varl) replace
