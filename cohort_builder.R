# Author : Fabian Yii                          
# Email  : fabian.yii@ed.ac.uk

rm(list=ls())
library(dplyr)

## Read the cleaned tabular data in long format (14913 eyes; 7470 RE & 7443 LE)
d  <- read.csv("data/UKB/cleaned_data_long_MRI_all.csv")


#############################################################################################
############################# Quality control & building cohort #############################
#############################################################################################

# Include eyes with a lapse of no more than 2 years between 1st and 2nd follow-up visits
# 1771 eyes of 891 individuals left 
d <- subset(d, assessmentLapse <= 2)

## Include eyes with refractive error and keratometry data
# 1664 eyes of 855 individuals left 
d <- d[!is.na(d$SER) & !is.na(d$meanCornealRadius_V1), ] 

## Include only eyes where VA is available
# 1661 eyes of 855 individuals left
d <- d[!is.na(d$VA), ]

## Include only eyes with good VA
# 1029 eyes of 650 individuals left 
d <- d[d$VA<=0, ]

## Include eyes without chorioretinal, globe or scleral disorders
# 1002 eyes of 633 individuals left 
d <- d[!d$chorioretinalDiseases & !d$scleralDiseases & !d$globeDiseases, ]

## Include eyes without strabismus
# 1000 eyes of 631 individuals left 
d <- d[!d$strabismus, ]

## Include eyes without nystagmus
# 1000 eyes of 631 individuals left 
d <- d[!d$nystagmus, ]

## Include eyes without hypertension
# 693 eyes of 435 individuals left 
d <- d[!d$hypertension, ]

## Include eyes without diabetes
# 679 eyes of 427 individuals left
d <- d[!d$diabetes, ]


## Add a new column indicating eye
d$eye <- "LE"
for(i in 1:nrow(d)){
  if(grepl(21016, d$fundus_V1[i])){d$eye[i] <- "RE"}
} 
d <- d %>% relocate(id, eye)

## Save data frame
write.csv(d, 
          "data/UKB/cleaned_data_long_MRI_cohort.csv",
          row.names=FALSE)

## Remove eyes with fundus images of "reject" quality and save the resultant dataframe
qualityDF       <- read.csv("data/UKB/fundusQuality.csv")
includeBool     <- d$fundus_V1 %in% subset(qualityDF, quality!="reject")$fundus
d               <- d[includeBool,] # 441 eyes of 303 individuals 
write.csv(d,
          "data/UKB/cleaned_data_long_MRI_cohort_nonRejectFundusQuality.csv",
          row.names=FALSE)















