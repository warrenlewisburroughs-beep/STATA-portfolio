*-------------------------*
* Stata Sample		      |
* Warren Burroughs        |
* Data Cleaning and       |
*	Generating Variables  |
*-------------------------|

clear all
set more off
version 17

* Your directory here:
global wd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Assignments\assignment_Stata_2\01_data"
cd $wd


*-----------------------------------------------------------------------------


**Problem: We are given data on funding proposals and their ratings from reviewers (a score from 1 to 5, with 5 being the highest). However, with different reviewers scoring, it would be better if we normalize the scores for each reviewer. How do we do this?

**Solution: Generate variables for each reviewer that shows each score they gave to a proposal. Using these data, calculate the mean and standard deviation to get a standard score.


use q3_proposal_review
rename Rewiewer1 Reviewer1
rename Review1Score Reviewer1Score // Variable names spelled incorrectly/there are discrepancies in naming

*Make a loop so each reviewer has their own variable which records each score they've given
foreach r in ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3 {
	gen `r'_score = Reviewer1Score if Reviewer1 =="`r'"
	replace `r'_score = Reviewer2Score if Reviewer2 =="`r'"
	replace `r'_score = Reviewer3Score if Reviewer3 =="`r'"
	egen mean_`r' = mean(`r'_score) //Generate variable for each reviewer's mean and standard deviation
	egen sd_`r' = sd(`r'_score)
}

*Generate the standardized score after the nonstandardized score (Variable with a lot of missing observations for now)
gen stand_r1_score=., af(Reviewer1Score)
gen stand_r2_score=., af(Reviewer2Score)
gen stand_r3_score=., af(Reviewer3Score)
*In each of the standardized variables, add the standardized score by using the formula St Score = (score-mean)/sd
foreach r in ahs103 am3944 ass95 ato12 bp557 fg443 ft227 glp38 mp1792 nbs56 nd549 oo140 sa1600 scb136 yc577 ynd3 {
	replace stand_r1_score = (Reviewer1Score - mean_`r')/sd_`r' if Reviewer1=="`r'"
	replace stand_r2_score = (Reviewer2Score - mean_`r')/sd_`r' if Reviewer2=="`r'"
	replace stand_r3_score = (Reviewer3Score - mean_`r')/sd_`r' if Reviewer3=="`r'"
}

*Generate a variable that shows the average standard score for each proposal
gen avg_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score)/3, af(AverageScore)

*Rank each proposal based on average standard score.
gsort -avg_stand_score
gen rank=_n, af(avg_stand_score)








