*-------------------------*
* Stata Sample		      |
* Warren Burroughs        |
* Automation with loops   |
*-------------------------|

clear all
set more off
version 17

* Your directory here:
global wd "C:\Users\warre\OneDrive\Desktop\Georgetown\SecondSemester\Experimental_Design\Assignments\assignment_Stata_2\01_data"
cd $wd


*--------------------------------------------------------------------------------


**Problem: We are given GPS coordinates of 111 villages. We want to divide (approximately) equally the 19 enumerators households so they can travel the shortest distance.

**Solution: We use the cluster kmeans command to create clusters of villages. For clusters with too many enumerators (more than 6), we remove extra enumerators and assign them to clusters that do not have enough enumerators using the code geodist.  


*--------------------------------------------------------------------------------

use q3_GPS_Data.dta
set seed 4000 /// So we get the same group each time

*Step 1) Create spatial groups: 
*--------------------------------------------------
**Use "cluster kmeans" command to create 19 clusters, using the mean of latitude and longitude and longitude as the center.
cluster kmeans lat lon, k(19) name(cluster_id)

sort cluster_id
tab cluster_id
//Unfortunately, these groups are not equal!
//Some enumerator's will get lots of villages, and some will get few
//We want each to have 6 to make the work fair
 
 
*Step 2) Deduce which id is closest to the cluster center and keep the closests ones 
*---------------------------------------------------------------------------
**Figure out what coordinates are the centers
bysort cluster_id: egen clus_lat = mean(latitude)
bysort cluster_id: egen clus_lon= mean(longitude)

**Use geodist command to generate a variable that shows each id's distance from center
geodist latitude longitude clus_lat clus_lon, gen(distance_center)

**Now rank them based on distance
bysort cluster_id (distance_center): gen rank=_n

**Assign the 6 closest house. Additional houses are marked missing.
gen final_cluster_group = cluster_id if rank<=6


*Step 3) Assign remaining ids with new spatial groups 
*-------------------------------------------------------
**Count and store which observations are missing
count if final_cluster_group == .
local remaining = r(N)

**Run a loop which assigns each remaining id to a new group_id
while `remaining' > 0 {
	
	*Store the id we are currently working on assigning
	quietly sum id if final_c == .
	local current_id = r(min) 
	//Takes the next id reamining and stores it as 'current_id'
	//The minimum value is always the next remaining id for every loop
	
	*Find current_id coordinates
	quietly sum latitude if id == `current_id'
	local cur_lat = r(mean)
	quietly sum longitude if id == `current_id'
	local cur_lon = r(mean)
	//Since only one coordinate for `current_id', the mean is always the right latitude and longitude
	
	*Record current size of cluster
	capture drop current_size //Drop this variable from previous loops
	bysort final_cluster_group: egen current_size = count(id)
	//This variable counts the number of observations in each final cluster group-- giving us the current size
	
	*Calculate distance from cluster center
	capture drop temp_dist //Drop this variable from previous loops 
	geodist `cur_lat' `cur_lon' clus_lat clus_lon, gen(temp_dist)
	//Creates a variable that measures the distance of the current id to each cluster's coordinate.
	
	*Don't look at full clusters or unassaigned groups
	quietly replace temp_dist = . if current_size >=6 | final_cluster_group == .
	
	*Sort so closest cluster is at the top
	sort temp_dist
	local best_cluster = final_cluster_group[1]
	//We've now found the best cluster for this ID!
	
	*Assign house to best cluster
	replace final_cluster_group = `best_cluster' if id == `current_id'
	//For this id, mark the final_cluster_group variable as their best cluster
	
	*Rerun loop with new count of remaining houses
	quietly count if final_cluster_group == .
	local remaining = r(N)
}


*Step 4) Clean up 
*--------------------------------------------------------------
* Drop the temporary variables
drop clus_lat clus_lon distance_center rank current_size temp_dist

* View final group sizes
tabulate final_cluster