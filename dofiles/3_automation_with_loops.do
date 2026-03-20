*-------------------------*
* Stata Sample		      |
* Warren Burroughs        |
* Automation with loops   |
*-------------------------|

clear all

* Your directory here:
global wd ""
cd $wd


*--------------------------------------------------------------------------------


**Problem: We are given GPS coordinates of 111 villages. We want to divide (approximately) equally the 19 enumerators households so they can travel the shortest distance.

**Solution: We use the cluster kmeans command to create clusters of villages. For clusters with too many enumerators (more than 6), we remove extra enumerators and reassign them to the closest cluster. Although not a perfect solution, the outcome is one where enumerators do not have to travel far distances.


*--------------------------------------------------------------------------------

use q3_GPS_Data.dta, clear
set seed 53697152 ///So we get the same group each time

*Step 1) Create spatial groups: 
*--------------------------------------------------
**Use "cluster kmeans" command to create 19 clusters, using the mean of latitude and longitude and longitude as the center.
cluster kmeans lat lon, k(19) generate(cluster_id)

sort cluster_id
tab cluster_id
//Unfortunately, these groups are not equal!
//Some enumerator's will get lots of villages, and some will get few
//We want each to have 6 to make the work fair


*Step 2) Calculate distances from each village to each cluster's center:
*--------------------------------------------------
*Loop through 19 clusters to find centers and calculate the distance
levelsof cluster_id, local(clusters)

foreach c of local clusters {
	quietly sum latitude if cluster_id == `c', meanonly
	local lat_`c' = r(mean)
	quietly sum longitude if cluster_id == `c', meanonly
    local lon_`c' = r(mean)
	
	//Generate variables that shows a village's distance from every cluster center
	geodist latitude longitude `lat_`c'' `lon_`c'', gen(dist_to_`c')
}


*Step 3) Assign the six closest villages to their clusters
*--------------------------------------------------
gen dist_to_own =.

//How far away is each point from their cluster center?
foreach c of local clusters {
    quietly replace dist_to_own = dist_to_`c' if cluster_id == `c'
}

//Rank and keep the closest six
bysort cluster_id (dist_to_own): gen rank = _n
gen final_cluster_group = cluster_id if rank <= 6


*Step 4) Village assignments
*--------------------------------------------------
//First, remove from consideration the distances for clusters that are already full (size >= 6)
foreach c of local clusters {
    quietly count if final_cluster_group == `c'
    local size_`c' = r(N)
    
    if `size_`c'' >= 6 {
        replace dist_to_`c' = . 
    }
}

//Have a while loop that goes through each village that does not have a final cluster group and assigns them the one with the closest cluster center
quietly count if final_cluster_group == .
local remaining = r(N)
while `remaining' > 0 {
    
    //Find the minimum distance to any open cluster for unassigned villages 
    capture drop min_avail_dist
    quietly egen double min_avail_dist = rowmin(dist_to_1 - dist_to_19) if final_cluster_group == .
    //Use "double" to match the format of dist_to_* 
	
    //Sort so the village closest to an open cluster is the first observation
    sort min_avail_dist
    
    //Identify which cluster the first observation is closest to
    local best_c = .
    foreach c of local clusters {
        if dist_to_`c'[1] == min_avail_dist[1] {
            local best_c = `c'
            continue, break //Stop looking once we find the match
        }
    }
    
    //Assign the village to its best cluster
    replace final_cluster_group = `best_c' in 1
    
    //Update the size of the cluster we just added to
    local size_`best_c' = `size_`best_c'' + 1
    
    //If that cluster just hit six, remove it from future consideration
    if `size_`best_c'' >= 6 {
        replace dist_to_`best_c' = .
    }
    
    //Rerun loop with new count of cluster groups with less than six villages
    quietly count if final_cluster_group == .
    local remaining = r(N)
}

*Step 5) Clean up
*--------------------------------------------------
drop dist_to_* dist_to_own rank min_avail_dist
tab final_cluster_group


*Step 6) View clusters in a scatterplot
*--------------------------------------------------
twoway scatter lat lon, colorvar(final_cluster_group) colordiscrete colorrule(phue)







