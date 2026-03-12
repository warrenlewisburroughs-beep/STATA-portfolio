*-------------------------*
* Stata Sample		      |
* Warren Burroughs        |
* Data Reshaping and      |
*	Merging               |
*-------------------------|

clear all

* Your directory here:
global wd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Assignments\assignment_Stata_2\01_data"
cd $wd


*-----------------------------------------------------------------------------
*Reshaping


**Problem: We are given election data in an excel document that is not formatted to be used in STATA. We would like the dataset to be in wide form, with each observation being a ward, and each political party has a variable listing how many votes they got in the district. 
**Solution: Clean the data (including trimming, deleting dashes or underscores, and making variables and observations lowercase) and then reshape.


**Step 1) Import File 
*-----------------------------------------------------------
**Make a global of the excel file
global TanzaniaPSLE "q4_Tz_election_2010_raw.xls"

**Trying to open the excel file results in broken data
import excel $TanzaniaPSLE, cellrange(A5:I7927) firstrow
//Specifying cell range drops title
//First row becomes varnames


**Step 2) Clean data
*-----------------------------------------------------------
*Drop Sex (not in template)
drop SEX G

*Ensure that there are no extra spaces in the string variables
replace REGION = trim(REGION)
replace DISTRICT = trim(DISTRICT)
replace COSTITUENCY = trim(COSTITUENCY)
replace WARD = trim(WARD)

*Fix formatting
replace WARD = WARD[_n-1] if missing(WARD)
replace COSTITUENCY = COSTITUENCY[_n-1] if missing(COSTITUENCY)
replace DISTRICT = DISTRICT[_n-1] if missing(DISTRICT)
replace REGION = REGION[_n-1] if missing(REGION)
drop if _n==1

*Remove characters that shouldn't be in varnames
replace POLITICALPARTY = subinstr(POLITICALPARTY, " - ", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, "-", "_", .)
replace POLITICALPARTY = subinstr(POLITICALPARTY, " ", "", .)


**Step 3) Generate and clean variables in preperation for reshaping 
*-------------------------------------------------------------------
*Generate a variable that counts how many candidates are running in each ward
bysort REGION DISTRICT COSTITUENCY WARD: egen tot_cand = count(WARD)
order tot_cand, af(WARD)

*Generate a variable that displays the total votes in each ward
replace TTL = "0" if regexm(TTL, "UN OPPOSSED") == 1 //Need numeric observation
destring TTL, replace
bysort REGION DISTRICT COSTITUENCY WARD: egen ward_total_votes = total(TTLVOTES)

*Generate an id variable that uniquely identifies each observation to easily sort the data
sort REGION DISTRICT COSTITUENCY WARD
gen id = _n

*Make each observation and variable lowercase
foreach v of varlist * {
	capture replace `v' = strlower(`v')
}
rename *, lower

*Rename for efficiency
rename ttlvotes votes


**Step 4) Reshape and Clean 
*---------------------------------------------------------------
*Reshape using votes as the stub, region/district/costituency/candidatename as the unique identification, and politicalparty as the observations becoming variables. Use string option as j is a string variable.
reshape wide votes, i(region district cost ward candidatename) j(politicalparty) string

*Order variables
order tot_cand ward_total_votes id, af(ward)
order id, af(ward_total_votes)

*Generate a variable that identifies which number a candidate is within a ward
sort id
bysort region district cost ward: gen ward_num = _n, af(id)


*We need to collapse the dataset so there's only on ward observation per constituency
*By generating a variable that shows the total of a party's number of votes, each observation within a ward in this new variable has the number of votes, allowing us to collapse later.
foreach var of varlist votes* {
	bysort region district cost ward: egen _`var' = total(`var') if `var' != 0 //Ignore unopposed candidates for now; will address in the loop after next
	order _`var', af(`var')
}

*Note missings
foreach var of varlist _votes*{
	replace `var' = . if `var' == 0 
}

*Address candidates that ran unopposed and drop the variable made by the reshaping
foreach var of varlist votes*{
	replace _`var' = 0 if `var'==0
	drop `var'
}

*Make the dataset display one ward per observation per costituency
duplicates drop cost ward, force


*Step 5) Finishing Touches 
*-----------------------------------------------------
drop ward_num candidatename
sort id
replace id = _n //Update id variable to reflect current dataset


*-----------------------------------------------------------------------------
*Merging


**Problem: We need to take information from an excel document and merge it to an existing STATA file.
**Solution: Clean the imported excel data so discrepencies are removed and match variable names to merge. 

*Step 1) Import Excel with variables as firstrow
*-------------------------------------------------
import excel q2_CIV_populationdensity.xlsx, firstrow


*Step 2) Data cleaning to match the master file 
*-------------------------------------------------
*Drop all observations that are not department level data
keep if strpos(NOMCIRCONSCRIPTION, "DEPARTEMENT") != 0

*Make the observations and variables lowercase
foreach v of varlist * {
	capture replace `v' = strlower(`v')
}
rename *, lower

*Clean department level data so that they no longer include the word department or their prefixes
replace nomcirconscription = subinstr(nomcirconscription, "departement d' ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement d'", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement du ", "", .)
replace nomcirconscription = subinstr(nomcirconscription, "departement de ", "", .)

*Rename to match master
rename nomcirconscription dept

*Save
save q2_excel_import.dta, replace


*Step 3) Clean and Merge 
*------------------------------------------------------------
clear
use q2_CIV_Section_0.dta

*Use decode to turn variable from int to string
decode b06_departemen, gen(dept)

*Clean mispelled observations
replace dept = "arrah" if dept == "arrha"

*Merge many to 1
merge m:1 dept using "q2_excel_import.dta"

drop _merge




