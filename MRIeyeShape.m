%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  Author: Fabian SL Yii                  %
%               Email: fabian.yii@ed.ac.uk                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; clc; close all;
homeDir = "";
addpath(fullfile("matlabHelperFunctions", "imEllipsoid"));

%%%%%%% Read segmentation info
segInfo    = load(fullfile(homeDir, "imageOutputs", "UKB", "MRIsegmentation", "groundTruthMed.mat"));
segPaths   = segInfo.gTruthMed.LabelData;
segPaths   = segPaths(segPaths ~= "");
% RE pixels are labelled as "1", LE pixels are labelled "2"
labelIDs   = segInfo.gTruthMed.LabelDefinitions.PixelLabelID;
labelNames = segInfo.gTruthMed.LabelDefinitions.Name;

%%%%%%% Read dummy output excel file
df = readtable(fullfile(homeDir, "CSVoutputs", "UKB", "MRIresults.xlsx"));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% START ANALYSIS %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for i=1:length(segPaths)
    %%%%%%% Read segmented data 
    segPath  = segPaths(i);
    [~,ID]   = fileparts(segPath); ID = str2num(ID)
    mask     = medicalVolume(segPaths(i));
    data     = mask.Voxels; % segmentation data
    %%%%%%% Extract RE and LE segmentations, and calculate volume (mm3)
    if ismember(labelNames(1), "RE") && ismember(labelNames(2), "LE")
        RE = data==labelIDs(1); 
        LE = data==labelIDs(2); 
    elseif ismember(labelNames(1), "LE") && ismember(labelNames(2), "RE")
        LE = data==labelIDs(1); 
        RE = data==labelIDs(2); 
    else
       throw(exception);
    end

   %%%%%%% If RIGHT eye is available and eligible for analysis
   if length(unique(RE))>1
       % volshow(RE, RenderingStyle="GradientOpacity"); % show RE
       volumeRE                   = nnz(RE)*mask.VoxelSpacing(1)*mask.VoxelSpacing(2)*mask.VoxelSpacing(3);
       %%% Fit ellipsoid (https://uk.mathworks.com/matlabcentral/fileexchange/34104-image-ellipsoid-3d)
       %%% elliRE output: [XC, YC, ZC, A, B, C, PHI, THETA, PSI], where
       %%% [XC YC ZC] are the centroid coordinates [AL, width, height]; 
       %%% [A B C] are semidiameter of parameters A, B and C;
       %%% [PHI THETA PSI] are euler angles [z, y, x axis rotation sequence]
       [elliRE, rotationMatrixRE] = imEquivalentEllipsoid(RE); % RE data
       REparamAxes                = findAxes(rotationMatrixRE, 1);
       
       %%% Visualise fitted ellipsoid
       % figure; hold on; 
       % drawEllipsoid(elliRE);
       % drawEllipsoid(elliRE, 'drawEllipses', true, 'EllipseWidth', 0.2); 
       % p = patch( isosurface(RE,0) );                % create isosurface patch
       % isonormals(RE, p)                             % compute and set normals
       % set(p, 'FaceColor','r', 'EdgeColor','none')   % set surface props
       % daspect([1 1 1])                              % axes aspect ratio
       % box on, grid on                               % set axes props
       % camproj perspective                           % use perspective projection
       % camlight, lighting phong, alpha(0.25)     
       % axis equal;
       % axis off
       
       %%% Compute prolateness & vertex curvature;
       %%% Refer to https://iovs.arvojournals.org/article.aspx?articleid=2182758#89703720
       %%% and https://iovs.arvojournals.org/article.aspx?articleid=2535988.
       %%% REparamAxes tells us which axis (i.e. axial length, width, height) 
       %%% parameters A, B and C correspond to in RE 
       [REcX, REcY, REcZ, A, B, C, REphi, REtheta, REpsi] = struct('x', num2cell(elliRE)).x;
       params       = [A B C];
       REsemiAL     = params(find(strcmp(REparamAxes,"AL")));
       REsemiWidth  = params(find(strcmp(REparamAxes,"width")));
       REsemiHeight = params(find(strcmp(REparamAxes,"height")));
       % Scale dimensional metrics (i.e. semidiameters) by their corresponding
       % pixel resolution (mm/pixel)
       REsemiAL     = REsemiAL*mask.VoxelSpacing(1);
       REsemiWidth  = REsemiWidth*mask.VoxelSpacing(2);
       REsemiHeight = REsemiHeight*mask.VoxelSpacing(3);
       % Asphericity: oblate if positive, circle if zero, prolate if negative
       qREhor       = ((REsemiWidth^2) / (REsemiAL^2)) - 1;  % horizontal oblateness
       qREver       = ((REsemiHeight^2) / (REsemiAL^2)) - 1; % vertical oblateness
       % Vertex curvature
       curveREhor   = REsemiAL / (REsemiWidth^2);
       curveREver   = REsemiAL / (REsemiHeight^2); 
       % Vertex radius of curvature (mm)
       radiusREhor   = 1/curveREhor; 
       radiusREver   = 1/curveREver;
       %%% Save results
       df(df.id==ID & df.eye=="RE", "volume")          = {volumeRE};
       df(df.id==ID & df.eye=="RE", "cX")              = {REcX};
       df(df.id==ID & df.eye=="RE", "cY")              = {REcY};
       df(df.id==ID & df.eye=="RE", "cZ")              = {REcZ};
       df(df.id==ID & df.eye=="RE", "semiAL")          = {REsemiAL};
       df(df.id==ID & df.eye=="RE", "semiWidth")       = {REsemiWidth};
       df(df.id==ID & df.eye=="RE", "semiHeight")      = {REsemiHeight};
       df(df.id==ID & df.eye=="RE", "asphericityHor")  = {qREhor};
       df(df.id==ID & df.eye=="RE", "asphericityVer")  = {qREver};
       df(df.id==ID & df.eye=="RE", "vertexCurvHor")   = {curveREhor};
       df(df.id==ID & df.eye=="RE", "vertexCurvVer")   = {curveREver};
       df(df.id==ID & df.eye=="RE", "vertexRadiusHor") = {radiusREhor};
       df(df.id==ID & df.eye=="RE", "vertexRadiusVer") = {radiusREver};    
   end

   %%%%%%% If LEFT eye is available and eligible for analysis
   if length(unique(LE))>1
       % volshow(LE, RenderingStyle="GradientOpacity"); % show LE
       volumeLE                   = nnz(LE)*mask.VoxelSpacing(1)*mask.VoxelSpacing(2)*mask.VoxelSpacing(3);
       [elliLE, rotationMatrixLE] = imEquivalentEllipsoid(LE); % LE data
       LEparamAxes                = findAxes(rotationMatrixLE, 1);
       
       %%% Visualise fitted ellipsoid
       % figure; hold on; 
       % drawEllipsoid(elliLE);
       % drawEllipsoid(elliLE, 'drawEllipses', true, 'EllipseWidth', 0.2, 'FaceColor', 'green'); 
       % p = patch( isosurface(LE,0) );                
       % isonormals(LE, p)                             
       % set(p, 'FaceColor','#0072BD', 'EdgeColor','none')   
       % daspect([1 1 1])                              
       % box on, grid on                               
       % camproj perspective                           
       % camlight, lighting phong, alpha(0.25)     
       % axis equal;
       % axis off;
       
       [LEcX, LEcY, LEcZ, A, B, C, LEphi, LEtheta, LEpsi] = struct('x', num2cell(elliLE)).x;
       params       = [A B C];
       LEsemiAL     = params(find(strcmp(LEparamAxes,"AL")));
       LEsemiWidth  = params(find(strcmp(LEparamAxes,"width")));
       LEsemiHeight = params(find(strcmp(LEparamAxes,"height")));
       LEsemiAL     = LEsemiAL*mask.VoxelSpacing(1);
       LEsemiWidth  = LEsemiWidth*mask.VoxelSpacing(2);
       LEsemiHeight = LEsemiHeight*mask.VoxelSpacing(3);
       qLEhor       = ((LEsemiWidth^2) / (LEsemiAL^2)) - 1;  
       qLEver       = ((LEsemiHeight^2) / (LEsemiAL^2)) - 1; 
       curveLEhor   = LEsemiAL / (LEsemiWidth^2);
       curveLEver   = LEsemiAL / (LEsemiHeight^2); 
       radiusLEhor  = 1/curveLEhor; 
       radiusLEver  = 1/curveLEver;
       df(df.id==ID & df.eye=="LE", "volume")          = {volumeLE};
       df(df.id==ID & df.eye=="LE", "cX")              = {LEcX};
       df(df.id==ID & df.eye=="LE", "cY")              = {LEcY};
       df(df.id==ID & df.eye=="LE", "cZ")              = {LEcZ};
       df(df.id==ID & df.eye=="LE", "semiAL")          = {LEsemiAL};
       df(df.id==ID & df.eye=="LE", "semiWidth")       = {LEsemiWidth};
       df(df.id==ID & df.eye=="LE", "semiHeight")      = {LEsemiHeight};
       df(df.id==ID & df.eye=="LE", "asphericityHor")  = {qLEhor};
       df(df.id==ID & df.eye=="LE", "asphericityVer")  = {qLEver};
       df(df.id==ID & df.eye=="LE", "vertexCurvHor")   = {curveLEhor};
       df(df.id==ID & df.eye=="LE", "vertexCurvVer")   = {curveLEver};
       df(df.id==ID & df.eye=="LE", "vertexRadiusHor") = {radiusLEhor};
       df(df.id==ID & df.eye=="LE", "vertexRadiusVer") = {radiusLEver};
   end
end


writetable(df, fullfile(homeDir, "CSVoutputs", "MRIresults.xlsx"));
display("Done!");









