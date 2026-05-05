# Hands-On Exercise Linking Census Data to Health Surveys
Using IPUMS Demographic and Health Surveys (IPUMS DHS) and IPUMS International Historical Geographic Information System (IHGIS) collections

This repository contains supporting materials for a hands-on exercise linking contextual data from population and agricultural censuses with health survey data freely available from: Demographic and Health Surveys (IPUMS DHS) - harmonized individual records from DHS program surveys conducted around the world - and International Historical Geographic Information System (IPUMS IHGIS) - consistently formatted tables of population and agricultural censuses around the world.

## Overview
The IPUMS Demographic and Health Surveys (IPUMS DHS) and IPUMS International Historical Geographic Information System (IHGIS) have collaborated on a new feature enabling users to easily link contextual data from the censuses in IHGIS to individual-level records in IPUMS DHS. The new linking feature uses the DHS cluster points to identify the corresponding IHGIS unit where each respondent lives and provides the IHGIS unit code as a variable on DHS records. Population and agricultural census data from IHGIS are then easily joined to the records based on the unit code. IHGIS data are typically available at the second administrative level and often for even smaller geographic units. The fine-grained geography and richness of these collections facilitate a wide variety of interdisciplinary research. 

## Files contained in this repository:
- Word document with step-by-step instructions on how to request extracts and download the necessary data and files from IPUMS DHS and IPUMS IHGIS to answer a sample research question
- R scripts that walks through data preparation, exploration, and analysis for this research question using linking variables and separately using full crosswalk files.
- Slides with screenshots from IPUMS DHS and IPUMS IHGIS websites as a visual aid on how to get data
- Webinar presentation slides on linking IPUMS DHS and IPUMS IHGIS
