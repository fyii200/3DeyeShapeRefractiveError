# install.packages("lmerTest")
library(lmerTest)
library(sjPlot)
library(car)
library(ggplot2)

## Clear workspace
rm(list=ls())

## Set working directory to parent directory
setwd("/Users/fabianyii/Library/CloudStorage/OneDrive-UniversityofEdinburgh/Projects/eyeShape/")

## Read the cleaned tabular data in long format (eyes with adequate quality fundas images)
SERdata                 <- read.csv("data/UKB/cleaned_data_long_MRI_cohort_nonRejectFundusQuality.csv")
SERdata$assessmentLapse <- round(SERdata$assessmentLapse, 5)

## Read the csv file with MRI-derived eye shape parameters
eyeShapeData                 <- read.csv("CSVoutputs/UKB/MRIresults.csv")
eyeShapeData                 <- subset(eyeShapeData, reject=="n") # only include eyes with adequate qualty MRI scans (assessed manually)
eyeShapeData$assessmentLapse <- round(eyeShapeData$assessmentLapse, 5)

## Merge both datasets
d    <- merge(SERdata, eyeShapeData, by=c("id", "eye", "assessmentLapse"))
d$id <- factor(d$id)

## Read the csv file with OD and fovea parameters
ODfovParameters                  <- read.csv("CSVoutputs/UKB/ODfoveaResults.csv")
names(ODfovParameters)[1]        <- "fundus_V1"
ODfovParameters$ODovality        <- ODfovParameters$ODmajorLength/ODfovParameters$ODminorLength

## Merge both datasets
d <- merge(d, ODfovParameters, by="fundus_V1")

## Read the csv files containing vessel parameters and merge them
arteryConcavity           <- read.csv("CSVoutputs/UKB/arteryParabolaResults.csv")
veinConcavity             <- read.csv("CSVoutputs/UKB/veinParabolaResults.csv")
AutoMorphVesselParameters <- read.csv("CSVoutputs/UKB/vesselResults.csv")
vesselParameters          <- merge(arteryConcavity, veinConcavity, by="name", suffixes=c("_artery", "_vein"))
vesselParameters          <- merge(AutoMorphVesselParameters, vesselParameters, by="name")

## Merge vessel df with the main df
names(vesselParameters)[1] <- "fundus_V1"
d <- merge(d, vesselParameters, by="fundus_V1")

## Characteristics of included participants
table(d[!duplicated(d$id),]$sex) # sex distribution
table(d[!duplicated(d$id),]$ethnic) # ethnicity

########################### Helper function ###########################
# Function: calculates object size by accounting for the effect of
# magnification due to ametropia
OM <- function(measured_size, SER, CR, GH=TRUE, telecentric=FALSE){
  
  if(GH==TRUE){
    denominator <- (17.21 / CR) + 1.247 + (SER / 17.455)
    q           <- 1/denominator} 
  else{
    denominator <- (17.21 / CR) + 1.247 + (SER / 17.455)
    q           <- 1/denominator
    p           <- 0.015*SER + 1.521 }
  
  # If camera can be assumed to be telecentric
  if(telecentric==TRUE){p <- 1.37}
  # If camera cannot be assumed to be telecentric
  if(telecentric==FALSE){p <- 0.015*SER + 1.521}
  
  # Calculate true size
  true_size <- p * q * measured_size
  
  return(true_size) }
####################################################################
## Adjust dimensional metrics for ocular magnification
d$adjCRAE_Knudtson <- OM(d$CRAE_Knudtson, d$SER_V1, d$meanCornealRadius_V1)
d$adjCRVE_Knudtson <- OM(d$CRVE_Knudtson, d$SER_V1, d$meanCornealRadius_V1)
d$ODfovAdjDist     <- OM(d$ODfovDist, d$SER_V1, d$meanCornealRadius_V1)
d$ODadjArea        <- OM(d$ODminorLength, d$SER_V1, d$meanCornealRadius_V1) * OM(d$ODmajorLength, d$SER_V1, d$meanCornealRadius_V1) * pi/4 ## OD area calculated using the standard ellipse formula

#### Eye shape parameters and posterior segment volume vs SER ####
# Horizontal asphericity vs SER
tab_model(lmer(asphericityHor ~ scale(SER_V1) + scale(ageV2) + sex + (1|id), d), digits=4)
# Vertical asphericity vs SER
tab_model(lmer(asphericityVer ~ scale(SER_V1) + scale(ageV2) + sex + (1|id), d), digits=4)
# Posterior segment volume 
tab_model(lmer(volume ~ scale(SER_V1) + scale(ageV2) + sex + (1|id), d), digits=4) 
tab_model(lmer(volume ~ scale(SER_V1) + scale(ageV2) + sex + scale(height) + (1|id), d), digits=4) # height additionally included as a covariate


##############################################################################
###################### Retinal predictors of eye shape #######################
##############################################################################

############################ Univariable analyses ############################
### Horizontal asphericity vs retinal features ###
tab_model(lmer(asphericityHor ~ scale(ODfovAdjDist) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(abs(ODorientation)) + (1|id), d), digits=4) 
tab_model(lmer(asphericityHor ~ scale(ODovality) + (1|id), d), digits=4) 
tab_model(lmer(asphericityHor ~ scale(ODadjArea) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(ODfovAngle) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(conc_rp_artery) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(conc_rp_vein) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(Tortuosity_density_combined) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(FD_combined) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(adjCRAE_Knudtson) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(adjCRVE_Knudtson) + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(FPI) + (1|id), d), digits=4)
### Vertical asphericity vs retinal features ###
tab_model(lmer(asphericityVer ~ scale(ODfovAdjDist) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(abs(ODorientation)) + (1|id), d), digits=4) 
tab_model(lmer(asphericityVer ~ scale(ODovality) + (1|id), d), digits=4) 
tab_model(lmer(asphericityVer ~ scale(ODadjArea) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(ODfovAngle) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(conc_rp_artery) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(conc_rp_vein) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(Tortuosity_density_combined) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(FD_combined) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(adjCRAE_Knudtson) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(adjCRVE_Knudtson) + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(FPI) + (1|id), d), digits=4)

########################### Multivariable analyses ###########################
### Horizontal asphericity vs retinal features ###
tab_model(lmer(asphericityHor ~ scale(ODfovAdjDist) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(abs(ODorientation)) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4) 
tab_model(lmer(asphericityHor ~ scale(ODovality) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4) 
tab_model(lmer(asphericityHor ~ scale(ODadjArea) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(ODfovAngle) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(conc_rp_artery) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(conc_rp_vein) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(Tortuosity_density_combined) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(FD_combined) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(adjCRAE_Knudtson) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(adjCRVE_Knudtson) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityHor ~ scale(FPI) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
### Vertical asphericity vs retinal features ###
tab_model(lmer(asphericityVer ~ scale(ODfovAdjDist) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(abs(ODorientation)) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4) 
tab_model(lmer(asphericityVer ~ scale(ODovality) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4) 
tab_model(lmer(asphericityVer ~ scale(ODadjArea) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(ODfovAngle) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(conc_rp_artery) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(conc_rp_vein) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(Tortuosity_density_combined) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(FD_combined) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(adjCRAE_Knudtson) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(adjCRVE_Knudtson) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)
tab_model(lmer(asphericityVer ~ scale(FPI) + scale(SER_V1) + scale(ageV1) + sex + (1|id), d), digits=4)


##############################################################################
###################################  Plots ###################################
##############################################################################
## Set plot theme
myTheme <- theme_linedraw() + theme(panel.grid.minor=element_blank(),
                                    panel.grid.major=element_blank(),
                                    strip.background=element_rect(colour=NA, fill="gray90"),
                                    strip.text=element_text(colour="black", face="bold"),
                                    panel.border=element_rect(colour=NA, fill=alpha("gray", 0.05)),
                                    plot.margin = margin(.2,.5,.2,.2, "cm"),
                                    axis.title.x=element_text(margin=margin(t=10)),
                                    axis.title.y=element_text(margin=margin(r=10)),
                                    axis.text =element_text(size=6)) 

## Horizontal/vertical asphericity vs SER
ggplot(d) + geom_point(aes(x=SER_V1, y=asphericityHor, fill="Horizontal"), col="maroon", alpha=0.4, size=2.5) + 
  geom_point(aes(x=SER_V1, y=asphericityVer, fill="Vertical"), col="darkblue", alpha=0.4, size=2.5) +
  guides(fill=guide_legend(override.aes=list(col=c("maroon", "darkblue"), size=3))) +
  scale_fill_discrete(name="Asphericity meridian") +
  labs(x="Spherical equivalent refraction (D)", y="Asphericity") +
  scale_x_continuous(breaks=round(seq(-12, 5.5, 2.5), 1)) +
  scale_y_continuous(breaks=round(seq(-0.3, 1.1, 0.2), 1)) +
  geom_hline(yintercept=0, color="gray80", linetype="dashed") +
  geom_abline(intercept=0.5685, slope=0.0484, col="maroon", linewidth=0.2) +
  geom_abline(intercept=0.8414, slope=0.0438, col="darkblue", linewidth=0.2) +
  myTheme + theme(legend.position="top", axis.text =element_text(size=8))
ggsave("manuscript/figures/asphericityVsSER.pdf", width=6.5, height=5.5)
  
## Vertex curvature vs horizontal/vertical asphericity
ggplot(d) + geom_point(aes(x=asphericityHor, y=vertexCurvHor, fill="Horizontal"), col="maroon", alpha=0.4, size=2.5) + 
  geom_point(aes(x=asphericityVer, y=vertexCurvVer, fill="Vertical"), col="darkblue", alpha=0.4, size=2.5) +
  guides(fill=guide_legend(override.aes=list(col=c("maroon", "darkblue"), size=4))) +
  scale_fill_discrete(name="Meridian") +
  labs(x="Asohericity", y="Posterior pole curvature") +
  myTheme + theme(legend.position="top", axis.text =element_text(size=10))
ggsave("manuscript/figures/suppFigure.pdf", width=8.5, height=6.5)

















