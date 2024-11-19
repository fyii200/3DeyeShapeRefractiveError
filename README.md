## Step 1. Participant selection and image quality control
<pre>
clean_raw_data.R          : R script for processing the raw UK Biobank dataframe into a format compatible with 'cohort_builder.R'.
cohort_builder.R          : R script for selecting eligible participants for the study.
fundusQualityAssessment.m : MATLAB script for manual quality assessment of fundus photographs.
</pre>

## Step 2. Manual segmentation of posterior eye volume
*PS: Using MATLAB's [Medical Image Labeler](https://uk.mathworks.com/help/medical-imaging/ug/get-started-with-medical-image-labeler.html)*

#### &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; High myopia &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Low hyperopia

<p align="left">
  <img src="https://github.com/user-attachments/assets/5f47efbf-0d97-496b-bece-24f218766c77" width="350" />
  <img src="https://github.com/user-attachments/assets/5cc4eb50-d006-4f7f-8922-1b9755f7d968" width="350" /> 
</p>


## Step 3. Ellipsoid fitted to each segmented posterior eye volume
<pre>
MRIeyeShape.m         : MATLAB script for fitting ellipsoid and deriving eye shape parameters.
matlabHelperFunctions : Folder containing helper functions for 'MRIeyeShape.m'. 

Note that helper functions including 'createCirclesMask.m' (mathworks.com/matlabcentral/fileexchange/47905-createcirclesmask-m) & 'imEquivalentEllipsoid.m' (uk.mathworks.com/matlabcentral/fileexchange/34104-image-ellipsoid-3d) were not written by myself and are not included in this repository. However, they can be accessed through the links provided.
</pre>

&nbsp;&nbsp;&nbsp; *PS: ellipsoids in green; segmentation overlays in pink/red*
<p align="left">
  <img src="https://github.com/user-attachments/assets/011ea01d-e96a-4313-bba2-099cf4bd0a19" width="400" /> 
</p>


## Step 4. Imaging features derived from fundus photographs
<pre>
ODfovea_segment.m  : MATLAB script facilitating manual optic disc and foveal segmentation using the Image Segmenter App.
ODfovea_analysis.m : MATLAB script for deriving optic disc and foveal parameters from the segmented optic disc and fovea.
vascularArcade     : Folder containing python scripts for deriving temporal arterial/venous concavity from the segmented retinal vasculature.  
</pre>
*Retinal vasculature was segmented automatically using [AutoMorph](https://github.com/rmaphoh/AutoMorph/tree/main), which also 
derived central retinal arteriolar/venular equivalent, vessel tortuosity and vessel fractal dimension*
<p align="left">
  <img src="https://github.com/user-attachments/assets/e098026d-c5ec-478c-9295-08275ad5412b" width="700" /> 
</p>


## Step 5. Statistical analysis
<pre>
statisticalAnalysis.R : R script for performing the regression analysis described in the manuscript.
</pre>




