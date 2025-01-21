# Shrinking the Federal Workforce Analysis
This repository contains code and data for an analysis of reducing the federal workforce at the Core Based Statistical Area (CBSA) level by 75 percent by Jonathan Schwabish.

## Background
This repository contains code and data for Reducing the Federal Workforce by 75 Percent: Consequences for Local Economies and Unemployment Rates Across the US. The brief simulates what would happen if the Department of Government Efficiency (DOGE) goal of cutting 75 percent of the federal workforce occurs. The analysis uses counts of the federal workforce at the CBSA-level in March 2024 provided through a request to the Office of Personnel Management (OPM). Those data are matched to Bureau of Labor Statistics (BLS) Local Area Unemployment Statistics (LAUS) data.  

## Repository Contents
The Stata code reads and cleans in the various OPM and BLS datasets, merges them, and includes some basic summary statistics calculations. The data and log file are placed in a `RawData/ folder`.
```
├── opm_counties.do                  <- Conduct processing of files in /RawData and produce output.
├── RawData                          <- Store raw data here.
    ├── CT_cbsa_titles.xlsx                        
    ├── CTmapping.xlsx                             
    ├── Governmentwide CBSA as of March 2024.xlsx  
    ├── lma-directory-2025.xlsx                    
    ├── non2301areas.xlsx                          
    ├── LAUS files the user must download          
├── README.md                        <- This readme file.
├── .gitignore                       <- File ensuring that large files from LAUS don't get pushed to this repository.
```
The analysis in `opm_counties.do` should not require any special user-written commands or ado-files.  

## Data

The BLS data are drawn from the [BLS LAUS flat files](https://download.bls.gov/pub/time.series/la/) and included in this repository (e.g., `la.data.64.County.txt`). All data are loaded from .txt or Excel (.xlsm) files, cleaned, saved as .dta (Stata) files, and merged together where necessary. 

OPM data were provided via direct request by the author and are stored in an Excel file; a second tab in that file includes data documentation and details. The CBSA codes in the OPM data reflect the 2023 definitions per [OMB Bulletin No. 23-01](https://www.whitehouse.gov/wp-content/uploads/2023/07/OMB-Bulletin-23-01.pdf). Current BLS data use the geographic delineations set forth in [OMB Bulletin No. 18-03](https://www.whitehouse.gov/wp-content/uploads/2018/04/OMB-BULLETIN-NO.-18-03-Final.pdf). Thus, the best way to put things on a comparable geographic basis and tied to the 23-01 update bulletin is to use the county-to-23-01 mapping in the first worksheet of the [2025 Labor Market Area Directory](https://nam12.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.bls.gov%2Flau%2Flma-directory-2025.xlsx&data=05%7C02%7Cjschwabish%40urban.org%7C1ebc42f484f34b47af2f08dd2f5e2b17%7C648e80b8b4a64750b333996d512f8ce0%7C1%7C0%7C638718804009813499%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=X4y4PpFJi97JmxyfHyi4fPsl3e%2BCxBLwvR9GXl41VVc%3D&reserved=0) file (`lma-directory-2025.xlsx`) provided by BLS. This mapping enables county-level aggregations for the desired time period(s) to the delineations per OMB Bulletin No. 23-01. 

There are 27 records in the OPM list corresponding to micropolitan areas that dropped out of the OMB delineations per bulletin No. 23-01 and are therefore not included in the analysis. For example, the Atmore, AL MSA, consisting of Escambia County, AL, existed under the 2010-based standards through OMB Bulletin No. 20-01 but is not included in any 2023 CBSA under the 2020-based standards. Those 27 records represent 3,348 federal workers or less than 0.2 percent of the full sample. 

Aggregations for Connecticut are handled separately because of the planned implementation of the nine planning regions in Connecticut’s new county equivalents as outlined in the [June 2022 Federal Register](https://www.federalregister.gov/documents/2022/06/06/2022-12063/change-to-county-equivalents-in-the-state-of-connecticut). The LAUS program does publish estimates for all 169 county subdivisions in Connecticut and thus those values can be matched to the nine planning regions and then to the 2023-based CBSAs (la.data.64.Connecticut.txt). Fortunately, BLS was kind enough to provide a file that maps relevant LAUS area codes to OPM 23-01 CBSA codes (CTmapping.xlsx and CT_cbsa_titles.xlsx). 

It is worth noting that, effective March 2025, the federal statistical areas in the LAUS database will be converted to the [23-01 OMB basis](https://www.bls.gov/lau/notices/2024/upcoming-changes-to-metropolitan-statistical-area-delineations.htm). 

To run `opm_counties.do`, you will have to change filepaths, and download the following [BLS LAUS flat files](https://download.bls.gov/pub/time.series/la/) to `/RawData`:

* `la.area`
* `la.area_type`
* `la.data.13.Connecticut`
* `la.data.64.County`
* `la.measure`


### Contact

Please contact [Jonathan Schwabish](https://www.urban.org/author/jonathan-schwabish) with questions.
