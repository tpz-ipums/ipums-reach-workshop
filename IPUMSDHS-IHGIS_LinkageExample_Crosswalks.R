###################################
# This script walks through an example research question
# utilizing IPUMS DHS data linked to contextual data from IHGIS.
#
# Research question: In Uganda, what is the association between stunting 
# and causes of agricultural losses that may contribute to food shortages?
#
# General steps:
# 1. Load data from IPUMS DHS and IHGIS and calculate key variables
# 2. Join IHGIS data to DHS records
# 3. Use visualizations to explore the data
# 4. Construct a model to address the research question
#
##################################

library(tidyverse)
library(sf)
library(spdep)

## Set these file path/name variables to match how you saved the files

# CSV file downloaded from DHS
DHS_extract_data <- "ExerciseData/DHS_Uganda_Stunting_idhs_00004.csv"
# The IHGIS data table on households reporting food shortage
#   the file name should end with AAX_g2.csv
IHGIS_shortage_table <- "ExerciseData/UG2009agAAX_g2.csv"
# An IHGIS data table on agricultural losses due to climate/weather
#   the file name should contain ABD, ABE, ABF, ABG, or ABH
IHGIS_agloss_table <- "ExerciseData/UG2009agABE_g2.csv"
# Crosswalk file matching DHS cluster IDs to IHGIS geog units
xwalk_file <- "ExerciseData/UG2011DHS_UG2009ag_g2.csv"
# Shapefile of Uganda districts from IHGIS
UGg2_shp <- "ExerciseData/UG2009ag_g2.shp"

######
##-- Step 1: Load data from IPUMS DHS and IHGIS and calculate key variables --##
######

## Load DHS data 
DHS_2011 <- read.csv(DHS_extract_data) %>% 
  # Select the variables we will be using
  select(IDHSPID, IDHSHID, DHSID, 
         URBAN, AGE, UNIMPTOILETHH, EDYRTOTAL, KIDAGEMO,
         HWHAZWHO) %>% 
  # Create a factor variable that dichotomizes stunting
  mutate(stuntWHO = cut(HWHAZWHO,
                        breaks=c(min(HWHAZWHO), -200, 9990, 10000),
                        labels=c('Y','N', 'NIU')))
# reorder the levels of the factor so our logit model will be
# for odds of stunting
DHS_2011$stuntWHO <- ordered(DHS_2011$stuntWHO, levels = c("N", "Y", "NIU"))

## Load IHGIS data 
# Food shortage table for denominator
IHGIS_09_food_shortage <- read.csv(IHGIS_shortage_table) %>% 
  select(GISJOIN, shortage_univ = AAX001)
# Agricultural loss table
#  If you are using a cause other than drought, change the IHGIS table codes in the mutate()
IHGIS_09_agloss <- read.csv(IHGIS_agloss_table) %>% 
  replace(is.na(.), 0) %>% 
  # calculate the sum of households reporting moderate & severe losses
  mutate(num_hh_loss = ABE005 + ABE006) %>%
  select(GISJOIN, num_hh_loss)

# Join the shortage and ag loss tables to calculate the 
# percent of ag households reporting moderate or severe losses
IHGIS_09_keyvar <- IHGIS_09_food_shortage %>% 
  left_join(IHGIS_09_agloss, by = join_by(GISJOIN)) %>% 
  mutate(pct_hh_loss = (num_hh_loss/shortage_univ)*100) %>% 
  select(GISJOIN, pct_hh_loss)

######
##-- Step 2: Load crosswalk and link IHGIS data to DHS records --##
## Note that this step will be simpler when the linking variables are
## available directly in IPUMS DHS extracts
######

## Load the crosswalk file
xwalk_D11_I09 <- read.csv(xwalk_file)
# filter to the most likely unit for each clusterID
xwalk_D11_I09 <- xwalk_D11_I09 %>% group_by(DHSID) %>% 
  filter(IHGIS_PROP == max(IHGIS_PROP)) %>% 
  ungroup()

## Use crosswalk to join data
DHS11_IHGIS09 <- DHS_2011 %>% 
  # Join crosswalk to DHS to get IHGIS GISJOIN for each record
  left_join(xwalk_D11_I09, by = join_by(DHSID)) %>% 
  # drop cluster points not matched to an IHGIS unit due to having (0,0) coords
  filter(!is.na(IHGIS_GISJOIN)) %>% 
  # Join IHGIS data to DHS using GISJOIN  
  left_join(IHGIS_09_keyvar, by = join_by(IHGIS_GISJOIN == GISJOIN))

######
##-- Step 3: Use visualizations to explore the data
######

## A. Nationwide, what proportion of children are stunted?
#  calculate proportion
nrow(filter(DHS11_IHGIS09, stuntWHO == "Y"))/nrow(filter(DHS11_IHGIS09, stuntWHO != "NIU"))
#  make a simple bar chart
DHS11_IHGIS09 %>% 
  filter(stuntWHO == "Y" | stuntWHO == "N") %>% 
  ggplot(aes(x = stuntWHO)) + geom_bar(fill = "cornflowerblue") +
  geom_text(stat = "count",
            aes(label = after_stat(count)),
            vjust = 1.5) +
  labs(x = "Stunted (>2 SD below median)",
       y = "Children")

## B. What is the distribution of agricultural loss across districts?
# make a simple histogram
hist(IHGIS_09_keyvar$pct_hh_loss,
     col = "cornflowerblue",
     xlab = "% of agricultural households",
     ylab = "Districts",
     main = "Households experiencing moderate or severe agricultural losses")

## C. Where were the highest proportion of households affected by agricultural losses?
# load shapefile into an sf object
UGg2 <- read_sf(UGg2_shp) %>% 
  # drop polygons for lakes 
  filter(GISJOIN != "UG888") %>% 
  # join ag loss data to sf attribute tables
  left_join(IHGIS_09_keyvar, by = join_by(GISJOIN))
# make a map
ggplot() +
  geom_sf(data = UGg2, mapping = aes(fill = pct_hh_loss)) + 
  coord_sf() +
  scale_fill_distiller(name = "HH w/ag loss (%)",
                    palette = "Oranges",
                    direction = 1)

# D. How does stunting relate to agricultural losses?
# a not-very-useful scatter plot
DHS11_IHGIS09 %>% 
  # filter out children who were not measured for stunting
  # and those conceived after the agricultural census
  filter(stuntWHO != "NIU", KIDAGEMO > 23) %>% 
  ggplot(aes(x = pct_hh_loss, y = HWHAZWHO)) +
  geom_point() +
  geom_smooth(method = "lm") +
  labs(title = "Child stunting by district-level agricultural loss",
       x = "Percent households in district with loss",
       y = "Child's height-for-age Z-score")
# a somewhat more appropriate bar chart
# prepare binned % stunting data for the chart
stunt_v_loss <- DHS11_IHGIS09 %>% 
  filter(stuntWHO != "NIU", KIDAGEMO > 23) %>% 
  # create bins by % of households in the district experiencing loss
  mutate(bin_start = floor(pct_hh_loss / 10) * 10) %>% 
  # calculate the % of children in each bin who are stunted
  group_by(bin_start) %>% 
  summarise(stunt_pct = mean(stuntWHO == "Y")*100)
# make a bar chart
ggplot(stunt_v_loss, aes(x = bin_start, y=stunt_pct)) +
  geom_col(fill = "cornflowerblue", color = "white", width = 10, just = 0) +
  scale_x_continuous(breaks = seq(0, 100, by = 10), limits = c(0,100)) + 
  labs(
    title = "Percent children stunted by district-level agricultural loss",
    x = "Percent households in district with loss",
    y = "Percent of children stunted"
  )

######
##-- Step 4: Construct a model for the odds of stunting given
##            the percent of households in the district experiencing loss
##            and individual- and household-level controls
######

logit_model <- glm(stuntWHO ~ AGE + EDYRTOTAL + UNIMPTOILETHH + 
                     KIDAGEMO + as.factor(URBAN) +
                     pct_hh_loss,
                   family = "binomial",
                   data = filter(DHS11_IHGIS09, 
                                 stuntWHO != 'NIU' & KIDAGEMO > 23
                   ))
summary(logit_model)
