clear
capture log close

// CHANGE FILEPATHS TO YOUR LOCATION
cd "/Users/jon/Desktop/OPM/RawData"
log using "opm.log",replace
global filepath "/Users/jon/Desktop/OPM/Tables"


////**Import OPM data**////
import excel using "Governmentwide CBSA as of March 2024",sheet(Data) first clear
	rename CoreBasedStatisticalArea area
	rename Total opm
	gen opmfips=substr(area,1,5)
	destring opmfips,replace
	sort opmfips
save "opmdata",replace

*Get one name for each geography
use "opmdata",clear
	count
	gsort opmfips -opm
	by opmfips: gen n=_n
		tab n, m 
	keep if n==1 //Use the name for the area with the larger labor force
	drop n
	keep area opmfips
	count
save "opmdata_names",replace

*Add up #employees for each CBSA
use "opmdata",clear
	collapse (sum) opm,by(opmfips) 
	qui su opmfips
	assert r(N)==952 // Check number of CBSAs--should be 952.
	sort opmfips
save "opmdata_collapse",replace

*Add geographic names back to summed data
use "opmdata_collapse",replace
	merge 1:1 opmfips using "opmdata_names"
	assert _merge==3 //Test to confirm all merged
	drop _merge 
	sort opmfips
	order area opmfips opm
	gen blsfips=opmfips
save "newopmdata", replace



////**Import BLS DATA**////
**BLS flat files available at: https://download.bls.gov/pub/time.series/la/
insheet using "la.data.64.County.txt",clear //this is a big file, so do the conversion once
save "la.data.64.County",replace
use "la.data.64.County",clear
	keep if year==2024 
	keep if period=="M03"
	drop footnote*
	destring value, replace

	gen id27=substr(series_id,4,15) //create IDs based on BLS codes (this is the area code)
	gen id5=substr(series_id,8,5)
	gen series=substr(series_id,20,1) // series captures the variable from BLS data
	destring id5,replace
	destring series,replace
	gen seasonal=substr(series_id,3,1)
	drop if seasonal=="S"
	drop seasonal
save "bls_county_temp",replace

*Import area name data
insheet using "la.area",clear
	keep area*
	rename area_code id27
	keep if area_type_code=="F" // F: Counties and equivalents (see la.area_type file)
	sort id27
save "area",replace

*Create separate datasets for unemployment, employment, and labor force counts using codes from la.measure file
use "bls_county_temp",clear
	keep if series==4
	rename value unemployment
	sort series_id
	drop series
save "full_bls_unemployment",replace

use "bls_county_temp",clear
	keep if series==5
	rename value employment
	sort series_id
	drop series
save "full_bls_employment",replace

use "bls_county_temp",clear
	keep if series==6
	rename value laborforce
	sort series_id
	drop series
save "full_bls_laborforce",replace

*Merge datasets back together
use "full_bls_unemployment",clear
merge 1:1 id27 using "full_bls_employment"
assert _merge==3
drop _merge
merge 1:1 id27 using "full_bls_laborforce"
assert _merge==3
drop _merge
save "full_bls_county_temp", replace
export excel using "full_bls_county_temp",first(var) replace


////****Merge on Labor Market Areas (LMA) data: Maps counties to CBSAs***////
//Create Stata file for LMA data (note: LMA=CBSA). LMA data is at the county level and maps counties to CBSAs.
import excel using "lma-directory-2025.xlsx",sheet(Labor Market Areas) first clear
	sort CountyLAUSareacode
	drop if Record=="End of table"
save "lma-directory-2025.dta",replace

*Create file of one name for every LMA
use "lma-directory-2025.dta",clear
	sort LaborMarketAreacode
	bysort LaborMarketAreacode: gen n=_n
	keep if n==1
save "lma-directory-2025-oneobs.dta",replace

*Merge LMA data to BLS data
use "full_bls_county_temp",clear
	rename id27 CountyLAUSareacode
	sort CountyLAUSareacode
	count
merge 1:m CountyLAUSareacode using "lma-directory-2025.dta"
	sort _merge
	qui su _merge if _merge!=3
	assert r(N)==17 //17 non-matches are all Connecticut, which is done separately below
	keep if _merge==3 
	//sum unemployment, employment, labor force for all LMAs
collapse (sum) unemployment employment laborforce, by(LaborMarketAreacode)
	sort LaborMarketAreacode
save "lma-directory-2025_collapsed.dta",replace

*Merge LMA names back on
use "lma-directory-2025_collapsed.dta",clear
	merge 1:1 LaborMarketAreacode using "lma-directory-2025-oneobs"
	drop if StateFIPScode=="09" //CT
	assert _merge==3
	drop _merge
	sort LaborMarketAreacode	
	count
save "all-lma-directory-2025.dta",replace

*MERGE BLS & OPM DATA
use "all-lma-directory-2025.dta",clear
	rename LaborMarketAreacode blsfips
	destring blsfips,replace
	merge 1:1 blsfips using "newopmdata"
	tab _merge
	keep if _merge==3 //should have 918 (of 952) areas at this point: 952 - 7 in CT - 27 in non2301 areas 
save "full_bls_opm.dta",replace 



/////****CONNECTICUT****/////
//Repeat the above process for CT alone. CT is different because of change to planning areas; see Appendix in brief
//Read CT BLS data
import excel using "CTmapping.xlsx", first clear
	destring K,gen(opmfips)
	sort opmfips
save "CTmapping.dta",replace

import excel using "CT_cbsa_titles.xlsx", first clear
	sort opm_fips
	rename opm_fips opmfips
save "CT_cbsa_titles.dta",replace

*Create name file for CT
use "CTmapping.dta",clear
	bysort opmfips: gen n=_n
	keep if n==1
	keep opmfips newcountytitle
save "ctmapping_names",replace

insheet using "la.area",clear
	keep area*
	rename area_code id27
	sort id27
save "ct_area",replace

*Import BLS DATA: https://download.bls.gov/pub/time.series/la/
insheet using "la.data.13.Connecticut",clear
	keep if year==2024 
	keep if period=="M03"
	drop footnote*
	destring value, replace
	gen id27=substr(series_id,4,15) 
	gen id5=substr(series_id,8,5)
	gen series=substr(series_id,20,1)
	destring id5,replace
	destring series,replace
	gen seasonal=substr(series_id,3,1)
	drop if seasonal=="S"
	drop seasonal
	drop if id5==0 //this is full state values, so can drop
save "la.data.13.Connecticut.dta",replace

*Create separate datasets for unemployment, employment, and labor force counts, and then merge back together
*using codes from la.measure file
use "la.data.13.Connecticut.dta",clear
	keep if series==4
	rename value unemployment
	sort series_id
	drop series
save "ct_unemployment",replace

use "la.data.13.Connecticut.dta",clear
	keep if series==5
	rename value employment
	sort series_id
	drop series
save "ct_employment",replace

use "la.data.13.Connecticut.dta",clear
	keep if series==6
	rename value laborforce
	sort series_id
	drop series
save "ct_laborforce",replace

use "ct_unemployment",clear
merge 1:1 id27 using "ct_employment"
assert _merge==3
drop _merge
merge 1:1 id27 using "ct_laborforce"
assert _merge==3
drop _merge
save "full_ct_temp", replace
export excel using "full_ct_temp",first(var) replace

*Merge on area file and keep only cities and towns (la.area_type file)
use "full_ct_temp",clear
	merge 1:1 id27 using "ct_area"
	keep if area_type_code=="G" | area_type_code=="H" 
		//G:	Cities and towns above 25,000 population
		//H:	Cities and towns below 25,000 population in New England
	keep if _merge==3
	count
	drop _merge area_type_code
	rename id27 countysubdivisionareacode
	sort countysubdivisionareacode
merge 1:1 countysubdivisionareacode using "CTmapping.dta" //merge on CBSA codes
	assert _merge==3
	drop K _merge
collapse (sum) unemployment employment laborforce, by(opmfips) //add up by CBSA
	merge 1:1 opmfips using "ctmapping_names.dta"
	assert _merge==3
	drop _merge
save "ct_bls_opm",replace
merge 1:1 opmfips using "CT_cbsa_titles"
	assert _merge==3
	drop _merge newcountytitle county_title_showing
	rename cbsa_title newcountytitle
merge 1:1 opmfips using "newopmdata" //Merge on OPM data by CBSA
	keep if _merge==3
	drop _merge
	gen StateFIPScode="09"
	rename newcountytitle LaborMarketAreaname
save "ct_bls_opm",replace


	
//**Set up non2301 area file**//
//There are 27 records in the OPM data that are not consistent with 2023 CBSA names and thus are dropped; see Appendix in brief
import excel using "non2301areas.xlsx",first clear 
	sort opmfips
	drop record_no TF OPMState OPMName BLSAREA opmarea //clean up
save "non2301areas.dta",replace
	merge 1:1 opmfips using "newopmdata"
	keep if _merge==3
	qui su _merge
	assert r(N)==27 //should be 27 areas
	drop _merge
save "non2301areas_opm.dta",replace

*Merge on non2301 area file to main dataset
use "full_bls_opm.dta",clear
	qui su blsfips
	assert r(N)==918 //should have 918 (of 952) areas at this point: 952 - 7 in CT - 27 in non2301 areas 
	drop _merge
merge 1:1 opmfips using "non2301areas_opm"
	gen non2301=""
	replace non2301="non2301" if _merge==2
	drop _merge
	qui su blsfips
	assert r(N)==945 //should have 945 (of 952) areas: 952 - 7 in CT 
append using "ct_bls_opm"
	qui su blsfips
	assert r(N)==952 //should have all 952 areas
	drop Record Countyname n area
	assert blsfips==opmfips
	drop blsfips
	order opmfips LaborMarketAreaname unemployment employment laborforce opm
save "final_bls_opm_data_temp.dta",replace //this is the full dataset with all 952 areas
	
	
///**ANALYZE and COUNT**//
use "final_bls_opm_data_temp.dta",clear
*Get counts of OPM for non2301 areas and then drop
	qui su opm,d
		di r(sum)
		gen r1=r(sum)
	qui su opm if non2301=="non2301",d
		di r(sum)
		gen r2=r(sum)
	gen missing=100-(r2/r1*100)
	gen r3=r1-r2
	di r1 " " r2 " " r3
	su r1 r2 missing
	drop r1 r2 r3 missing
	
	****Drop non2301 areas****
	drop if non2301=="non2301"
	
	gen uer=(unemployment/laborforce)*100 //remember, because summed up by CBSA, need to calculate this here
	gen opmlf=(opm/laborforce)*100
		summarize opmlf, detail // check
		assert opm < laborforce if opm != . // check
	gen opm75=round(opm*.75,1)
		summarize opm75, detail // check
	gen newuer=((unemployment+opm75)/laborforce)*100
		summarize newuer, detail // check
	gen diff=newuer-uer
		summarize diff, detail //check
		
	*Calculate overall unemployment rate and adjusted unemployment rate
	qui su unemployment,d
	gen r1=r(sum)
	qui su employment,d
	gen r2=r(sum)
	qui su opm75,d
	gen r3=r(sum)
	di r1 " " r2 " " r3 " " r1/r2*100 " " (r1+r3)/r2*100
	drop r1 r2 r3
	
	*Format variables for export
	format uer %8.1f
	format newuer %8.1f
	format diff %8.1f
	format opmlf %8.1f
	
	gen area_name_temp=subinstr(LaborMarketAreaname,"Metropolitan Statistical Area","MSA",.)
	gen area_name=subinstr(area_name_temp,"Micropolitan Statistical Area","MiSA",.)
	drop area_name_temp 
	order opmfips area_name unemployment employment laborforce uer opm opm75 opmlf newuer diff

save "final_bls_opm_data",replace
export excel using "final_bls_opm_data.xlsx", replace first(var) keepcellfmt


//**Create data for tables**//
use "final_bls_opm_data",clear
 su opmfips
	assert r(N)==925 //952 - 27 = 925
	order area_name unemployment opm laborforce opmlf uer newuer diff
	keep area_name unemployment opm laborforce opmlf uer newuer diff
save "fulldata_tables.dta",replace
	gsort -laborforce //Largest 10 MSAs
	keep if _n<=10
export excel using "$filepath/topmsas.xlsx", replace first(var) keepcellfmt
use "fulldata_tables.dta",clear
	sort laborforce //Smallest 10 MSAs
	keep if _n<=10
export excel using "$filepath/smallmsas.xlsx", replace first(var) keepcellfmt
use "fulldata_tables.dta",clear
	gsort -opmlf //Largest areas by OPM share of labor force
	keep if _n<=10
export excel using "$filepath/opmlf.xlsx", replace first(var) keepcellfmt
*Put the full file in the Tables folder for further analysis if needed
use "final_bls_opm_data",clear
export excel using "$filepath/final_bls_opm_data.xlsx", replace first(var) keepcellfmt

	
clear
log close
