**matlabHelperFunctions**     : Folder containing miscellaneous helper functions for *MRIeyeShape.m* 

**vascularArcade**            : Folder containing Python scripts for deriving temporal arterial and venous concavity.

**MRIeyeShape.m**             : MATLAB script for deriving key parameters from 3D posterior eye segmentation, including horizontal/vertical asphericity and volume.

**ODfovea_analysis.m**        : MATLAB script for deriving optic disc and foveal parameters from the segmented optic disc and fovea.

**clean_raw_data.R**          : R script for preprocessing the raw UK Biobank dataframe into a format compatible with *cohort_builder.R*.

**cohort_builder.R**          : R script for selecting eligible UK Biobank participants for the study.

**fundusQualityAssessment.m** : MATLAB script for manual quality assessment of fundus photographs.

**statisticalAnalysis.R**     : R script for the regression analyses described in the manuscript.

Order in which the scripts are executed: 
1. **clean_raw_data.R**
2. **cohort_builder.R**
3. **fundusQualityAssessment.m**
4. Manual segmentation of disc and fovea
5. **ODfovea_analysis.m**
6. **vascularArcade**
7. Manual segmentation of posterior eye in MRI
8. **MRIeyeShape.m**
9. **statisticalAnalysis.R**

*To be further populated after conclusion of peer review*
