

Order in which the scripts are executed: 
1. **clean_raw_data.R**: R script for preprocessing the raw UK Biobank dataframe into a format compatible with *cohort_builder.R*.
2. **cohort_builder.R**: R script for selecting eligible UK Biobank participants for the study.
3. **fundusQualityAssessment.m**: MATLAB script for manual quality assessment of fundus photographs.
4. Manual segmentation of disc and fovea
5. **ODfovea_analysis.m**: MATLAB script for deriving optic disc and foveal parameters from the segmented optic disc and fovea.
6. **vascularArcade**: Folder containing Python scripts for deriving temporal arterial and venous concavity.
7. Manual segmentation of posterior eye in MRI
8. **MRIeyeShape.m**: MATLAB script for deriving key parameters from 3D posterior eye segmentation, including horizontal/vertical asphericity and volume.
9. **statisticalAnalysis.R**: R script for the regression analyses described in the manuscript.

Note: **matlabHelperFunctions** is a folder containing helper functions for *MRIeyeShape.m* 

*To be further populated after conclusion of peer review*
