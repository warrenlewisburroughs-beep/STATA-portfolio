*-------------------------*
* Stata Sample		      |
* Warren Burroughs        |
* String Processing       |
*-------------------------|

clear all
set more off
version 17

* Your directory here:
global wd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Assignments\assignment_Stata_2\01_data"
cd $wd


*-----------------------------------------------------------------------------


**Problem: We are given several pages of HTML code for school level data, and we must extract the data into something usable in STATA and using students as the unit of observation. 

**Solution: Use the code parse to turn school level data into student level data, reshape the data to be in long format, and use the code ustrregexs and ustrregexm to extract information from HTML code. 


*-----------------------------------------------------------------------------

use q1_psle_student_raw.dta


*Step 1) Reshape dataset to prepare for data extraction
*---------------------------------------------------------
*Split the html links so each variable has a student
split s, parse(">PS") gen(student_num_)

*Reshape the data so that the dataset is in long format
gen school_id = _n, bef(s)
//Note: Sometimes the reshaping breaks the do file. If this happens, go to line 37 and run the do file from here.
reshape long student_num_@, i(school_id) j(student)

*Drop extra variables
drop if student_num==""


*Step 2) Extract data
*-------------------------------------------------------------
*Generate Student Variables
gen cand_no = ustrregexs(1) if ustrregexm(student_num_, "(\d+-\d+)\s*<\s*(/FONT)")
gen prem_no = ustrregexs(1) if ustrregexm(student_num_, "(201\d+)\s*<\s*(/FONT)")
gen gender = ustrregexs(1) if ustrregexm(student_num_, "(M)\s*<\s*(/FONT)")
replace gender = ustrregexs(1) if ustrregexm(student_num_, "(F)\s*<\s*(/FONT)")
gen name = ustrregexs(2) if ustrregexm(student_num_, "(<P)\s*>\s*([A-Z]+\s*[A-Z]+\s*[A-Z]+)")
gen kiswahili_grade = ustrregexs(2) if ustrregexm(student_num_, "(Kiswahili)\s*-\s*([A-Z])")
gen english_grade = ustrregexs(2) if ustrregexm(student_num_, "(English)\s*-\s*([A-Z])")
gen maarifa = ustrregexs(2) if ustrregexm(student_num_, "(Maarifa)\s*-\s*([A-Z])")
gen hisabati= ustrregexs(2) if ustrregexm(student_num_, "(Hisabati)\s*-\s*([A-Z])")
gen science= ustrregexs(2) if ustrregexm(student_num_, "(Science)\s*-\s*([A-Z])")
gen uraia= ustrregexs(2) if ustrregexm(student_num_, "(Uraia)\s*-\s*([A-Z])")
gen average= ustrregexs(2) if ustrregexm(student_num_, "(Average Grade)\s*-\s*([A-Z])")

*Drop and replace code
drop student_num_ s
drop if cand_no == ""
replace schoolcode = subinstr(schoolcode, "shl_ps", "PS", .)
replace schoolcode = subinstr(schoolcode, ".htm", "", .)
bysort school_id: replace student = _n