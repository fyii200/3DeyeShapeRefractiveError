# Author : Fabian Yii                          
# Email  : fabian.yii@ed.ac.uk

## Clear workspace
rm(list=ls())

## Read raw tabular data
d  <- read.csv('data/UKB/FU_withFundus_brainMRI.csv')

#############################################################################################
#################### Create a new data frame to store cleaned variables #####################
#############################################################################################
## Sociodemographic & lifestyle factors (touchscreen-based questionnaire)
cleaned_data                  <- data.frame( 'id'=rep(NA, nrow(d)) )
cleaned_data$id               <- d$Participant.ID
cleaned_data$assessmentV1     <- as.POSIXct(d$Date.of.attending.assessment.centre...Instance.1, format = "%Y-%m-%d")
cleaned_data$assessmentV2     <- as.POSIXct(d$Date.of.attending.assessment.centre...Instance.2, format = "%Y-%m-%d")
cleaned_data$assessmentLapse  <- as.numeric(cleaned_data$assessmentV2-cleaned_data$assessmentV1)/365 # in year
cleaned_data$ageV1            <- d$Age.when.attended.assessment.centre...Instance.1
cleaned_data$ageV2            <- d$Age.when.attended.assessment.centre...Instance.2
cleaned_data$YOB              <- d$Year.of.birth
cleaned_data$sex              <- d$Sex
cleaned_data$ethnic           <- d$Ethnic.background...Instance.0
cleaned_data$townsend         <- d$Townsend.deprivation.index.at.recruitment
cleaned_data$edu              <- d$Qualifications...Instance.0                                                
cleaned_data$smoke            <- d$Smoking.status...Instance.0  
cleaned_data$weight           <- d$Weight...Instance.2 
cleaned_data$height           <- d$Standing.height...Instance.2
cleaned_data$BMI              <- d$Body.mass.index..BMI....Instance.2


## Distance VA (at 4m or 3m if px cannot read at 4m), IOP, corneal hysteresis (CH) & corneal resistance factor (CRF)
cleaned_data$RE_VA_V1         <- d$logMAR..final..right....Instance.1
cleaned_data$LE_VA_V1         <- d$logMAR..final..left....Instance.1
cleaned_data$RE_IOP_V1        <- d$Intra.ocular.pressure..Goldmann.correlated..right....Instance.1
cleaned_data$LE_IOP_V1        <- d$Intra.ocular.pressure..Goldmann.correlated..left....Instance.1
cleaned_data$RE_IOPcc_V1      <- d$Intra.ocular.pressure..corneal.compensated..right....Instance.1
cleaned_data$LE_IOPcc_V1      <- d$Intra.ocular.pressure..corneal.compensated..left....Instance.1
cleaned_data$RE_CH_V1         <- d$Corneal.hysteresis..right....Instance.1
cleaned_data$LE_CH_V1         <- d$Corneal.hysteresis..left....Instance.1
cleaned_data$RE_CRF_V1        <- d$Corneal.resistance.factor..right....Instance.1
cleaned_data$LE_CRF_V1        <- d$Corneal.resistance.factor..left....Instance.1

## Linked health data: primary care data, hospital admissions data, death register AND/OR self-reported data

############################################## Helper function ##############################################
# Raw data recorded as first occurrence date; the following function performs conversion to binary outcome, 
# where normal is represented by 0, while presence of disorder is represented by 1 
occurrenceDate_to_Binary <- function(dates){
  # "dates" is a vector which value represents the first #
  # occurrence date of a health disorder of interest     #
  
  ## Conversion rule ##
  # value=1 if year in which event occurs before 2019 (the year last visit was assumed to have taken place)
  # value=0 if year in which event occurs before 2019 (the year last visit was assumed to have taken place)
  occurenceDates  <- as.POSIXct(dates, format = "%Y-%m-%d")
  assessmentDates <- as.POSIXct(d$Date.of.attending.assessment.centre...Instance.2, format = "%Y-%m-%d")
  normalIndices   <- occurenceDates > assessmentDates                        # TRUE or NA represents normal
  binary          <- ifelse(normalIndices==TRUE | is.na(normalIndices), 0, 1) # 0 represents normal
  return(binary) }
########################################### Helper function ends ############################################

######### Systemic (edocrine/metabolic, blood, circulatory, congenital/chromosomal) disorders #########
# Note: disease is present or had happened if TRUE

# PRIMARY DIABETES (N=3679 at least one form of the disorder)
# Note 1: no cases of malnutrition-related diabetes (code E12)
# Note 2: Code E13 (other specified diabetes) includes secondary (postprocedural) diabetes so excluded (only 2 uncaptured cases anyway)
# https://icd.who.int/browse10/2019/en#/E10-E14
diabetes1             <- occurrenceDate_to_Binary(d$Date.E10.first.reported..insulin.dependent.diabetes.mellitus.)       # N=326 (type 1)
diabetes2             <- occurrenceDate_to_Binary(d$Date.E11.first.reported..non.insulin.dependent.diabetes.mellitus.)   # N=1794 (type 2)
diabetes3             <- occurrenceDate_to_Binary(d$Date.E14.first.reported..unspecified.diabetes.mellitus.)             # N=3209
cleaned_data$diabetes <- (diabetes1 + diabetes2 + diabetes3) > 0                                 

# ANAEMIA (N=2743 at least one form of the disorder)
# https://www.icd10data.com/ICD10CM/Codes/D50-D89/D50-D53
# https://www.icd10data.com/ICD10CM/Codes/D50-D89/D55-D59/D55-
# https://www.icd10data.com/ICD10CM/Codes/D50-D89/D60-D64/D63-
# https://www.icd10data.com/ICD10CM/Codes/D50-D89/D60-D64/D64-
anaemia1             <- occurrenceDate_to_Binary(d$Date.D50.first.reported..iron.deficiency.anaemia.)                             # N=1369
anaemia2             <- occurrenceDate_to_Binary(d$Date.D51.first.reported..vitamin.b12.deficiency.anaemia.)                      # N=253
anaemia3             <- occurrenceDate_to_Binary(d$Date.D52.first.reported..folate.deficiency.anaemia.)                           # N=22
anaemia4             <- occurrenceDate_to_Binary(d$Date.D53.first.reported..other.nutritional.anaemias.)                          # N=8
anaemia5             <- occurrenceDate_to_Binary(d$Date.D55.first.reported..anaemia.due.to.enzyme.disorders.)                     # N=4
anaemia6             <- occurrenceDate_to_Binary(d$Date.D63.first.reported..anaemia.in.chronic.diseases.classified.elsewhere.)    # N=44
anaemia7             <- occurrenceDate_to_Binary(d$Date.D64.first.reported..other.anaemias.)                                      # N=1454
cleaned_data$anaemia <- (anaemia1 + anaemia2 + anaemia3 + anaemia4 + anaemia5 + anaemia6 + anaemia7) > 0                 

# PRIMARY HYPERTENSION (N=17848 at least one form of the disorder)
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I10-I16/I10-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I10-I16/I11-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I10-I16/I12-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I10-I16/I13-
hypertension1             <- occurrenceDate_to_Binary(d$Date.I10.first.reported..essential..primary..hypertension.)       # N=17839
hypertension2             <- occurrenceDate_to_Binary(d$Date.I11.first.reported..hypertensive.heart.disease.)             # N=29
hypertension3             <- occurrenceDate_to_Binary(d$Date.I12.first.reported..hypertensive.renal.disease.)             # N=138
hypertension4             <- occurrenceDate_to_Binary(d$Date.I13.first.reported..hypertensive.heart.and.renal.disease.)   # N=2
cleaned_data$hypertension <- (hypertension1 + hypertension2 + hypertension3 + hypertension4) > 0                                      

# RHEUMATIC DISEASES (N=214 at least one form of the disorder)
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I00-I02
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I05-I09/I05-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I05-I09/I06-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I05-I09/I07-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I05-I09/I09-
rheumatic1                     <- occurrenceDate_to_Binary(d$Date.I00.first.reported..rheumatic.fever.without.mention.of.heart.involvement.) # N=150
rheumatic2                     <- occurrenceDate_to_Binary(d$Date.I01.first.reported..rheumatic.fever.with.heart.involvement.)               # N=3
rheumatic3                     <- occurrenceDate_to_Binary(d$Date.I02.first.reported..rheumatic.chorea.)                                     # N=7
rheumatic4                     <- occurrenceDate_to_Binary(d$Date.I05.first.reported..rheumatic.mitral.valve.diseases.)                      # N=32
rheumatic5                     <- occurrenceDate_to_Binary(d$Date.I06.first.reported..rheumatic.aortic.valve.diseases.)                      # N=7
rheumatic6                     <- occurrenceDate_to_Binary(d$Date.I07.first.reported..rheumatic.tricuspid.valve.diseases.)                   # N=19
rheumatic7                     <- occurrenceDate_to_Binary(d$Date.I09.first.reported..other.rheumatic.heart.diseases.)                       # N=7
cleaned_data$rheumaticDiseases <- (rheumatic1 + rheumatic2 + rheumatic3 + rheumatic4 + rheumatic5 + rheumatic6 + rheumatic7) > 0                                   

# MYOCARDIAL INFARCTION, aka heart attack (N=1418 at least one form of the disorder)
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I20-I25/I21-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I20-I25/I22-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I20-I25/I23-
myocardialInfarction1             <- occurrenceDate_to_Binary(d$Date.I21.first.reported..acute.myocardial.infarction.)                                          # N=1416
myocardialInfarction2             <- occurrenceDate_to_Binary(d$Date.I22.first.reported..subsequent.myocardial.infarction.)                                     # N=67
myocardialInfarction3             <- occurrenceDate_to_Binary(d$Date.I23.first.reported..certain.current.complications.following.acute.myocardial.infarction.)  # N=2
cleaned_data$myocardialInfarction <- (myocardialInfarction1 + myocardialInfarction2 + myocardialInfarction3) > 0 

# CARDIOMYOPATHY (N=126 at least one form of the disorder)
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I30-I5A/I42-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I30-I5A/I43-
cardiomyopathy1             <- occurrenceDate_to_Binary(d$Date.I42.first.reported..cardiomyopathy.)                                   # N=125
cardiomyopathy2             <- occurrenceDate_to_Binary(d$Date.I43.first.reported..cardiomyopathy.in.diseases.classified.elsewhere.)  # N=2
cleaned_data$cardiomyopathy <- (cardiomyopathy1 + cardiomyopathy2) > 0

# ISCHAEMIC HEART DISEASES (N=2123 at least one form of the disorder)
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I20-I25/I25-
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I20-I25/I24-
ischaemicHeartDisease1             <- occurrenceDate_to_Binary(d$Date.I25.first.reported..chronic.ischaemic.heart.disease.)      # N=2111
ischaemicHeartDisease2             <- occurrenceDate_to_Binary(d$Date.I24.first.reported..other.acute.ischaemic.heart.diseases.) # N=139
cleaned_data$ischaemicHeartDisease <- (ischaemicHeartDisease1 + ischaemicHeartDisease2) > 0

# CARDIAC ARREST (N=39)
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I30-I5A/I46-
cleaned_data$cardiacArrest <- occurrenceDate_to_Binary(d$Date.I46.first.reported..cardiac.arrest.) > 0

# HEART FAILURE (N=346)
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I30-I5A/I50-
cleaned_data$heartFailure  <- occurrenceDate_to_Binary(d$Date.I50.first.reported..heart.failure.) > 0

# MULTIPLE VALVULAR DISEASE (N=79) 
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I05-I09/I08-
cleaned_data$multipleValvularHeartDisease <- occurrenceDate_to_Binary(d$Date.I08.first.reported..multiple.valve.diseases.) > 0

# ATHEROSCLEROSIS (N=83) 
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I70-I79/I70-
cleaned_data$atherosclerosis <- occurrenceDate_to_Binary(d$Date.I70.first.reported..atherosclerosis.) > 0

# OTHER HEART DISEASES OR PERTINENT COMPLICATIONS (N=761), e.g. myocardial degeneration 
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I30-I5A/I51-
cleaned_data$otherHeartDiseases <- occurrenceDate_to_Binary(d$Date.I51.first.reported..complications.and.ill.defined.descriptions.of.heart.disease.) > 0

# DISEASES OF CAPILLARIES (N=152), e.g. Hereditary haemorrhagic telangiectasia
# https://www.icd10data.com/ICD10CM/Codes/I00-I99/I70-I79/I78-
cleaned_data$capillariesDiseases <- occurrenceDate_to_Binary(d$Date.I78.first.reported..diseases.of.capillaries.) 

# CEREBROVASCULAR DISEASES including stroke (N=1041 at least one form of the disorder)
# https://icd.who.int/browse10/2019/en#/I63
# https://icd.who.int/browse10/2019/en#/I64
# https://icd.who.int/browse10/2019/en#/I67
# https://icd.who.int/browse10/2019/en#/I68
cerebrovascularDisease1              <- occurrenceDate_to_Binary(d$Date.I63.first.reported..cerebral.infarction.)                                         # N=196
cerebrovascularDisease2              <- occurrenceDate_to_Binary(d$Date.I64.first.reported..stroke..not.specified.as.haemorrhage.or.infarction.)          # N=914
cerebrovascularDisease3              <- occurrenceDate_to_Binary(d$Date.I67.first.reported..other.cerebrovascular.diseases.)                              # N=166
cerebrovascularDisease4              <- occurrenceDate_to_Binary(d$Date.I68.first.reported..cerebrovascular.disorders.in.diseases.classified.elsewhere.)  # N=1
cleaned_data$cerebrovascularDiseases <- (cerebrovascularDisease1 + cerebrovascularDisease2 + cerebrovascularDisease3 + cerebrovascularDisease4) > 0

# THALASSAEMIA (N=79)
# https://www.icd10data.com/ICD10CM/Codes/D50-D89/D55-D59/D56-
cleaned_data$thalassaemia <- occurrenceDate_to_Binary(d$Date.D56.first.reported..thalassaemia.) > 0     

# SICKLE CELL DISORDERS (N=90)
# https://www.icd10data.com/ICD10CM/Codes/D50-D89/D55-D59/D57-
cleaned_data$sickle <- occurrenceDate_to_Binary(d$Date.D57.first.reported..sickle.cell.disorders.) > 0  

# SARCOIDOSIS (N=204)
# https://www.icd10data.com/ICD10CM/Codes/D50-D89/D80-D89/D86-
cleaned_data$sarcoidosis <- occurrenceDate_to_Binary(d$Date.D86.first.reported..sarcoidosis.) > 0  
 
# CYSTIC FIBROSIS (N=17)
# https://www.icd10data.com/ICD10CM/Codes/E00-E89/E70-E88/E84-
cleaned_data$cysticFibrosis <- occurrenceDate_to_Binary(d$Date.E84.first.reported..cystic.fibrosis.) > 0

# SPINA BIFIDA (N=34)
# https://www.icd10data.com/ICD10CM/Codes/Q00-Q99/Q00-Q07/Q05-
cleaned_data$spinaBifida <- occurrenceDate_to_Binary(d$Date.Q05.first.reported..spina.bifida.) > 0

# DOWN'S SYNDROME (N=5)
# https://www.icd10data.com/ICD10CM/Codes/Q00-Q99/Q90-Q99/Q90-
cleaned_data$downsSyndrome <- occurrenceDate_to_Binary(d$Date.Q90.first.reported..down.s.syndrome.) > 0

# EDWARDS OR PATAUS SYNDROME (N=3)
# https://www.icd10data.com/ICD10CM/Codes/Q00-Q99/Q90-Q99/Q91-
cleaned_data$edwards_or_pataus_syndrome <- occurrenceDate_to_Binary(d$Date.Q91.first.reported..edwards..syndrome.and.patau.s.syndrome.) > 0

# TURNER'S SYNDROME (N=4)
# https://www.icd10data.com/ICD10CM/Codes/Q00-Q99/Q90-Q99/Q96-
cleaned_data$turnersSyndrome <- occurrenceDate_to_Binary(d$Date.Q96.first.reported..turner.s.syndrome.) > 0

################## Conditions that affect the posterior segment of the eye ##################

# GLAUCOMA (N=1185 at least one form of the disorder)
# Note: code H40 includes eyes with ocular hypertension, "preglaucoma" or angle closure w/o glaucomatous damage
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H40-H42
glaucoma1             <- occurrenceDate_to_Binary(d$Date.H40.first.reported..glaucoma.)                                     # N=1185
glaucoma2             <- occurrenceDate_to_Binary(d$Date.H42.first.reported..glaucoma.in.diseases.classified.elsewhere.)    # N=1
cleaned_data$glaucoma <- (glaucoma1 + glaucoma2) > 0

# OPTIC NERVE DISORDERS (N=120 at least one form of the disorder)
# Note: examples of code H47 ('opticNerveDiseases3') include optic nerve hypoplasis & papilledema
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H46-H47
opticNerveDiseases1             <- occurrenceDate_to_Binary(d$Date.H46.first.reported..optic.neuritis.)                                                                       # N=44
opticNerveDiseases2             <- occurrenceDate_to_Binary(d$Date.H48.first.reported..disorders.of.optic..2nd..nerve.and.visual.pathways.in.diseases.classified.elsewhere.)  # N=0
opticNerveDiseases3             <- occurrenceDate_to_Binary(d$Date.H47.first.reported..other.disorders.of.optic..2nd..nerve.and.visual.pathways.)                             # N=79
cleaned_data$opticNerveDiseases <- (opticNerveDiseases1 + opticNerveDiseases2 + opticNerveDiseases3) > 0

# CHORIORETINAL DISORDERS (N=1487 at least one form of the disorder)
# Note: examples of code H31 ('chorioretinalDiseases2') are macular scars, solar retinopathy & choroidal degeneration
# Note: examples of code H35 ('chorioretinalDiseases6') are retinopathy of prematurity & macular degeneration
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H30-H36
chorioretinalDiseases1             <- occurrenceDate_to_Binary(d$Date.H30.first.reported..chorioretinal.inflammation.)                                # N=14
chorioretinalDiseases2             <- occurrenceDate_to_Binary(d$Date.H31.first.reported..other.disorders.of.choroid.)                                # N=39
chorioretinalDiseases3             <- occurrenceDate_to_Binary(d$Date.H32.first.reported..chorioretinal.disorders.in.diseases.classified.elsewhere.)  # N=0
chorioretinalDiseases4             <- occurrenceDate_to_Binary(d$Date.H33.first.reported..retinal.detachments.and.breaks.)                            # N=469
chorioretinalDiseases5             <- occurrenceDate_to_Binary(d$Date.H34.first.reported..retinal.vascular.occlusions.)                               # N=132
chorioretinalDiseases6             <- occurrenceDate_to_Binary(d$Date.H35.first.reported..other.retinal.disorders.)                                   # N=647
chorioretinalDiseases7             <- occurrenceDate_to_Binary(d$Date.H36.first.reported..retinal.disorders.in.diseases.classified.elsewhere.)        # N=374
cleaned_data$chorioretinalDiseases <- (chorioretinalDiseases1 + chorioretinalDiseases2 + chorioretinalDiseases3 + chorioretinalDiseases4 + chorioretinalDiseases5 + chorioretinalDiseases6 + chorioretinalDiseases7) > 0

# SCLERAL DISORDERS (N=112), e.g. staphyloma & scleritis
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H15-H22/H15-
cleaned_data$scleralDiseases <- occurrenceDate_to_Binary(d$Date.H15.first.reported..disorders.of.sclera.) > 0 

# DISEASES AFFECTING THE GLOBE (N=135 at least one form of the disorder), e.g. endophthalmitis & degenerative myopia (including mCNV)
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H43-H44/H44-
globeDiseases1             <- occurrenceDate_to_Binary(d$Date.H44.first.reported..disorders.of.globe.)                                                    # N=134         
globeDiseases2             <- occurrenceDate_to_Binary(d$Date.H45.first.reported..disorders.of.vitreous.body.and.globe.in.diseases.classified.elsewhere.) # N=1
cleaned_data$globeDiseases <- (globeDiseases1 + globeDiseases2) > 0  

# STRABISMUS (N=224 at least one form of the disorder)
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H49-H52/H49-
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H49-H52/H50-
strabismus1             <- occurrenceDate_to_Binary(d$Date.H49.first.reported..paralytic.strabismus.) # N=41
strabismus2             <- occurrenceDate_to_Binary(d$Date.H50.first.reported..other.strabismus.)     # N=188
cleaned_data$strabismus <- (strabismus1 + strabismus2) > 0

# NYSTAGMUS (N=26)
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H55-H57/H55-
cleaned_data$nystagmus <- occurrenceDate_to_Binary(d$Date.H55.first.reported..nystagmus.and.other.irregular.eye.movements.) > 0

################## Conditions that affect the cornea ##################

# CORNEAL DISORDERS (N=147)
# Include corneal pigmentations and deposits, bullous keratopathy, corneal oedema, corneal degeneration, 
# hereditary corneal dystrophies, keratoconus, other corneal deformities, etc.
# https://www.icd10data.com/ICD10CM/Codes/H00-H59/H15-H22/H18-/H18
cornea_disorders              <- occurrenceDate_to_Binary(d$Date.H18.first.reported..other.disorders.of.cornea.)
cleaned_data$cornea_disorders <- cornea_disorders > 0

## How many participants have good systemic and ocular health?
healthyNum <- sum(rowSums(cleaned_data[,26:55]) == 0)
paste(healthyNum, '(', paste(round(healthyNum/nrow(cleaned_data)*100,1), '%'), ')', 'are healthy') 
paste(sum(rowSums(cleaned_data[,26:47]) > 0), 'have at least one form of systemic condition')
paste(sum(rowSums(cleaned_data[,48:55]) > 0), 'have at least one form of ocular condition')

########## Compute median SER for each eye of each individual at visit 1 (Aug 2012 to June 2013) ##########
# SER (spherical equivalent refraction) = spherical power + 0.5*cylindrical power
# Right eye
cleaned_data$RE_sph_V1  <- apply(cbind(d$Spherical.power..right....Instance.1...Array.0,
                                       d$Spherical.power..right....Instance.1...Array.1,
                                       d$Spherical.power..right....Instance.1...Array.2,
                                       d$Spherical.power..right....Instance.1...Array.3,
                                       d$Spherical.power..right....Instance.1...Array.4),  # organise into columns
                                 1, median, na.rm=TRUE)                                    # average across columns 
cleaned_data$RE_cyl_V1  <- apply(cbind(d$Cylindrical.power..right....Instance.1...Array.0,
                                       d$Cylindrical.power..right....Instance.1...Array.1,
                                       d$Cylindrical.power..right....Instance.1...Array.2,
                                       d$Cylindrical.power..right....Instance.1...Array.3,
                                       d$Cylindrical.power..right....Instance.1...Array.4),  
                                 1, median, na.rm=TRUE)    
cleaned_data$RE_SER_V1  <- cleaned_data$RE_sph_V1 + 0.5*cleaned_data$RE_cyl_V1
# Corneal power: weak and strong meridians
cleaned_data$RE_cornealPowerWeak_V1 <- apply(cbind(d$X3mm.weak.meridian..right....Instance.1...Array.0,
                                                   d$X3mm.weak.meridian..right....Instance.1...Array.1,
                                                   d$X3mm.weak.meridian..right....Instance.1...Array.2,
                                                   d$X3mm.weak.meridian..right....Instance.1...Array.3,
                                                   d$X3mm.weak.meridian..right....Instance.1...Array.4),
                                             1, median, na.rm=TRUE)
cleaned_data$RE_cornealPowerStrong_V1 <- apply(cbind(d$X3mm.strong.meridian..right....Instance.1...Array.0,
                                                     d$X3mm.strong.meridian..right....Instance.1...Array.1,
                                                     d$X3mm.strong.meridian..right....Instance.1...Array.2,
                                                     d$X3mm.strong.meridian..right....Instance.1...Array.3,
                                                     d$X3mm.strong.meridian..right....Instance.1...Array.4),  
                                               1, median, na.rm=TRUE)
# Angles corresponding to weak and strong meridians
cleaned_data$RE_corneaWeakAngle_V1 <- apply(cbind(d$X3mm.weak.meridian.angle..right....Instance.1...Array.0,
                                                  d$X3mm.weak.meridian.angle..right....Instance.1...Array.1,
                                                  d$X3mm.weak.meridian.angle..right....Instance.1...Array.2,
                                                  d$X3mm.weak.meridian.angle..right....Instance.1...Array.3,
                                                  d$X3mm.weak.meridian.angle..right....Instance.1...Array.4),
                                            1, median, na.rm=TRUE)
cleaned_data$RE_corneaStrongAngle_V1 <- apply(cbind(d$X3mm.strong.meridian.angle..right....Instance.1...Array.0,
                                                    d$X3mm.strong.meridian.angle..right....Instance.1...Array.1,
                                                    d$X3mm.strong.meridian.angle..right....Instance.1...Array.2,
                                                    d$X3mm.strong.meridian.angle..right....Instance.1...Array.3,
                                                    d$X3mm.strong.meridian.angle..right....Instance.1...Array.4),  
                                              1, median, na.rm=TRUE)

# Convert corneal power to radius of curvature
# Note: 45 D = 7.5 mm (radius (diopters) = 337.5/power 
# https://www.ophthalmologyweb.com/Tech-Spotlights/26512-Instrument-Basics-Part-III-Corneal-Curvature/#:~:text=The%20keratometer%20measures%20the%20anterior,)%20%3D%20337.5%2Fr).
cleaned_data$RE_meanCornealRadiusWeak_V1   <- 337.5 / cleaned_data$RE_cornealPowerWeak_V1
cleaned_data$RE_meanCornealRadiusStrong_V1 <- 337.5 / cleaned_data$RE_cornealPowerStrong_V1
cleaned_data$RE_meanCornealRadius_V1       <- (cleaned_data$RE_meanCornealRadiusWeak_V1 + cleaned_data$RE_meanCornealRadiusStrong_V1)/2

# Left eye
cleaned_data$LE_sph_V1  <- apply(cbind(d$Spherical.power..left....Instance.1...Array.0,
                                       d$Spherical.power..left....Instance.1...Array.1,
                                       d$Spherical.power..left....Instance.1...Array.2,
                                       d$Spherical.power..left....Instance.1...Array.3,
                                       d$Spherical.power..left....Instance.1...Array.4),  
                                 1, median, na.rm=TRUE)                                      
cleaned_data$LE_cyl_V1  <- apply(cbind(d$Cylindrical.power..left....Instance.1...Array.0,
                                       d$Cylindrical.power..left....Instance.1...Array.1,
                                       d$Cylindrical.power..left....Instance.1...Array.2,
                                       d$Cylindrical.power..left....Instance.1...Array.3,
                                       d$Cylindrical.power..left....Instance.1...Array.4),  
                                 1, median, na.rm=TRUE)    
cleaned_data$LE_SER_V1  <- cleaned_data$LE_sph_V1 + 0.5*cleaned_data$LE_cyl_V1
# Corneal power: average across weak and strong meridians
cleaned_data$LE_cornealPowerWeak_V1 <- apply(cbind(d$X3mm.weak.meridian..left....Instance.1...Array.0,
                                                   d$X3mm.weak.meridian..left....Instance.1...Array.1,
                                                   d$X3mm.weak.meridian..left....Instance.1...Array.2,
                                                   d$X3mm.weak.meridian..left....Instance.1...Array.3,
                                                   d$X3mm.weak.meridian..left....Instance.1...Array.4),
                                             1, median, na.rm=TRUE)
cleaned_data$LE_cornealPowerStrong_V1 <- apply(cbind(d$X3mm.strong.meridian..left....Instance.1...Array.0,
                                                     d$X3mm.strong.meridian..left....Instance.1...Array.1,
                                                     d$X3mm.strong.meridian..left....Instance.1...Array.2,
                                                     d$X3mm.strong.meridian..left....Instance.1...Array.3,
                                                     d$X3mm.strong.meridian..left....Instance.1...Array.4),  
                                               1, median, na.rm=TRUE)
# Angles corresponding to weak and strong meridians
cleaned_data$LE_corneaWeakAngle_V1 <- apply(cbind(d$X3mm.weak.meridian.angle..left....Instance.1...Array.0,
                                                  d$X3mm.weak.meridian.angle..left....Instance.1...Array.1,
                                                  d$X3mm.weak.meridian.angle..left....Instance.1...Array.2,
                                                  d$X3mm.weak.meridian.angle..left....Instance.1...Array.3,
                                                  d$X3mm.weak.meridian.angle..left....Instance.1...Array.4),
                                            1, median, na.rm=TRUE)
cleaned_data$LE_corneaStrongAngle_V1 <- apply(cbind(d$X3mm.strong.meridian.angle..left....Instance.1...Array.0,
                                                    d$X3mm.strong.meridian.angle..left....Instance.1...Array.1,
                                                    d$X3mm.strong.meridian.angle..left....Instance.1...Array.2,
                                                    d$X3mm.strong.meridian.angle..left....Instance.1...Array.3,
                                                    d$X3mm.strong.meridian.angle..left....Instance.1...Array.4),  
                                              1, median, na.rm=TRUE)
# Convert corneal power to radius of curvature
cleaned_data$LE_meanCornealRadiusWeak_V1   <- 337.5 / cleaned_data$LE_cornealPowerWeak_V1 
cleaned_data$LE_meanCornealRadiusStrong_V1 <- 337.5 / cleaned_data$LE_cornealPowerStrong_V1 
cleaned_data$LE_meanCornealRadius_V1       <- (cleaned_data$LE_meanCornealRadiusWeak_V1 + cleaned_data$LE_meanCornealRadiusStrong_V1)/2

## Right eye and left eye fundus image name
cleaned_data$RE_fundus_V1                                 <- d$Fundus.retinal.eye.image..right....Instance.1...Array.0
cleaned_data[cleaned_data$RE_fundus_V1=="",]$RE_fundus_V1 <- d[cleaned_data$RE_fundus_V1=="",]$Fundus.retinal.eye.image..right....Instance.1...Array.1
cleaned_data$LE_fundus_V1                                 <- d$Fundus.retinal.eye.image..left....Instance.1...Array.0
cleaned_data[cleaned_data$LE_fundus_V1=="",]$LE_fundus_V1 <- d[cleaned_data$LE_fundus_V1=="",]$Fundus.retinal.eye.image..left....Instance.1...Array.1

## Right eye and left eye OCT name
cleaned_data$RE_OCT_V1                               <- d$OCT.image.slices..right....Instance.1...Array.0
cleaned_data[cleaned_data$RE_OCT_V1=="",]$RE_OCT_V1  <- d[cleaned_data$RE_OCT_V1=="",]$OCT.image.slices..right....Instance.1...Array.1
cleaned_data$LE_OCT_V1                               <- d$OCT.image.slices..left....Instance.1...Array.0
cleaned_data[cleaned_data$LE_OCT_V1=="",]$LE_OCT_V1  <- d[cleaned_data$LE_OCT_V1=="",]$OCT.image.slices..left....Instance.1...Array.1

# ## OCT quality indicators
# # Quality control based on 5 different indicators: image quality, ILM indicator, validity count & 2 motion indicators
# # We follow the OCT quality control protocol described in Ko et al. (https://www.sciencedirect.com/science/article/pii/S0161642016307394?via%3Dihub)
# # Right eye
# cleaned_data$RE_OCT_quality_score_V1     <- d$QC...Image.quality..right....Instance.1
# cleaned_data$RE_OCT_ILM_indicator_V1     <- d$QC...ILM.indicator..right....Instance.1
# cleaned_data$RE_OCT_valid_count_V1       <- d$QC...Valid.count..right....Instance.1
# cleaned_data$RE_OCT_max_motion_delta_V1  <- d$QC...Max.motion.delta..right....Instance.1
# cleaned_data$RE_OCT_min_motion_corr_V1   <- d$QC...Min.motion.correlation..right....Instance.1
# # Left eye
# cleaned_data$LE_OCT_quality_score_V1     <- d$QC...Image.quality..left....Instance.1
# cleaned_data$LE_OCT_ILM_indicator_V1     <- d$QC...ILM.indicator..left....Instance.1
# cleaned_data$LE_OCT_valid_count_V1       <- d$QC...Valid.count..left....Instance.1
# cleaned_data$LE_OCT_max_motion_delta_V1  <- d$QC...Max.motion.delta..left....Instance.1
# cleaned_data$LE_OCT_min_motion_corr_V1   <- d$QC...Min.motion.correlation..left....Instance.1

## MRI scans & derived measures
cleaned_data$MRI_T1_V2                             <- d$T1.structural.brain.images...NIFTI...Instance.2
cleaned_data$MRI_T2_V2                             <- d$T2.FLAIR.structural.brain.images...NIFTI...Instance.2
cleaned_data$MRI_brainVolume                       <- d$Volume.of.brain..grey.white.matter...Instance.2
cleaned_data$MRI_brainVolume_normalisedForHeadSize <- d$Volume.of.brain..grey.white.matter..normalised.for.head.size....Instance.2


## Convert data frame from wide format to long (each row corresponds to a unique eye from each individual)
# Create a data frame to store right eye data
RE                              <- cleaned_data[,1:15]
RE$eye                          <- 'RE'
RE                              <- cbind(RE, cleaned_data[, c(16, 18, 20, 22, 24, 26:55, 56:65, 76, 78, 80:83)]) 
colnames(RE)                    <- sub('RE_', '', colnames(RE)) # remove 'RE_" from column names
# Create a data frame to store left eye data
LE                              <- cleaned_data[,1:15]
LE$eye                          <- 'LE'
LE                              <- cbind(LE, cleaned_data[, c(17, 19, 21, 23, 25, 26:55, 66:75, 77, 79, 80:83)]) 
colnames(LE)                    <- sub('LE_', '', colnames(LE)) # remove 'LE_" from column names
# Concatenate right eye and left eye data frames (long format)
# 38996 eyes (19498 RE & LE) 
cleaned_data_long_all    <- rbind(RE, LE)                          # contain both eyes from all participants
# Include only those with  T2 MRI scans (14630 eyes; 7315 RE & LE)
cleaned_data_long_all    <- cleaned_data_long_all[cleaned_data_long_all$MRI_T2_V2!="", ]
# Include only eyes with fundus images (14535 eyes; 7256 RE & 7279 LE)
cleaned_data_long_all    <- cleaned_data_long_all[cleaned_data_long_all$fundus_V1!="", ] # note that OCT scans are available for all remaining eyes
# Save as csv
write.csv(cleaned_data_long_all,                                   # save as csv
          'data/UKB/cleaned_data_long_MRI_all.csv',
          row.names=FALSE) 




