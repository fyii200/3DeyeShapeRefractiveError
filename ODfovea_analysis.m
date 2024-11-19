%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  Author: Fabian SL Yii                  %
%               Email: fabian.yii@ed.ac.uk                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc, clear all, close all;

% Path to segmentation masks
masks_path    = fullfile("imageOutputs", "UKB", "ODfoveaMasks");   
% Specify directory in which the tabular data (OD/foveal parameters) should be saved
save_csv_path = fullfile("CSVoutputs", "UKB");

% Get mask names
mask_names = dir(masks_path);
% Only want to include filenames, i.e. exclude directories
mask_names = mask_names(~[mask_names.isdir]);
if mask_names(1).name == ".DS_Store"
    mask_names = mask_names(2:end);
end

% Read dataset
data = readtable(fullfile("data", "UKB", "cleaned_data_long_MRI_cohort.csv"));

% Cell array to store derived OD/foveal parameters of interest 
 result = {"fundus", "foveaX", "foveaY", "FPI", "ODx", "ODy", "ODmajorLength" ..., 
           "ODminorLength", "ODarea", "ODorientation", "ODfovDist", "ODfovAngle", "segmentation"; 
           [], [], [], [], [], [], [], [], [], [], [], [], []};

 f = waitbar(0, 'Starting');
 for i=1:length(mask_names)

    waitbar(i/length(mask_names), f, sprintf('Progress: %d %%', floor(i/length(mask_names)*100)));

    % name of the current mask
    mask_name = mask_names(i).name;

    % Get laterality (right or left eye) corresponding to this image from the dataset 
    this_data = data(strcmp(data.fundus_V1, mask_name),:);
    eye = this_data.eye;
    
    % save image name to the result cell array.
    result{i+1, 1} = mask_name; 
        
    % Read the segmentation mask (2D binary mask; 0 or 1)
    ODfoveaMask = imread(fullfile(masks_path, mask_name));        % 1536 x 2048

    %% Connected component analysis 
    cc = bwconncomp(ODfoveaMask);
    
    % Only compute OD parameters if OD mask is not empty
    if cc.NumObjects ~= 0
        % Compute centroid coordinates, area, major and minor axis length and orientation for each connected component
        stats = regionprops(cc, 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation');
        % "stats" should have two connected components: if RE, the first
        % and second components correspond to the fovea and OD, and vice
        % versa if LE
        if this_data.eye=="RE"
            fovIndex = 1;
            ODindex  = 2;
        else
            ODindex  = 1;
            fovIndex = 2;
        end
        
        % Extract fovea results
        fovStats = stats(fovIndex);
        fovCentroid = [fovStats.Centroid(1), fovStats.Centroid(2)];   % centroid coordinates
        % Compute median (background) pixel intensity, excluding zero pixels and pixels
        % corresponding to the disc, vessels and fovea
        rgbImg       = imread(fullfile("images", "UKB", "fundus", mask_name));                                                     % read original (RGB) fundus image
        grayImg      = rgb2gray(rgbImg);                                                                                           % convert RGB image to grayscale
        vesselMask   = imread(fullfile("imageOutputs", "UKB", "vesselMasks", "binary_vessel", "binary_process", mask_name));       % vessel mask
        vesselMask   = imresize(vesselMask, size(ODfoveaMask));                                                                    % make sure vessel mask has the same image dim as the original fundus image
        vesselMask   = vesselMask==255;                                                                                            % make sure vessel mask is binary (0 or 1)
        combinedMask = ODfoveaMask+vesselMask >= 1;                                                                                % combine vessel mask with OD-fovea masks
        combinedMask =  combinedMask==0;                                                                                           % invert the resultant mask such that background pixels become 1 and everything else is 0
        backgroundPI = median(grayImg(grayImg.*uint8(combinedMask) ~= 0));                                                         % compute median background pixel
        % imshow((double(rgbImg) .* double(~combinedMask))/255); % show masked RGB image
        % imwrite((double(rgbImg) .* double(~combinedMask))/255, "hyperopiaMaskedLE.png");
        
        % The fovea has an area of 1.75mm^2 (https://www.ncbi.nlm.nih.gov/books/NBK554706/pdf/Bookshelf_NBK554706.pdf, 
        % while the entire retina visible on a 45-degree FOV fundus (UK Bioabnk) has an area of around
        % 128mm^2 (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8547975/). Thus, The fovea takes up approximately
        % 1% of a 45-degree FOV fundus. The fundus images in UK Biobank have a circular retinal region with 
        % a radius of approximately 680 pixels, yielding a total of 1452700 (pi*680^2) pixels making up 
        % the entire retinal region. The foveal region therefore contains around 14527 pixels (1% of 1452700)
        % A circle with a radius of 70 pixels from the foveal centroid would capture this amount of pixels.
        maculaPI       = median(grayImg(createCirclesMask(grayImg, fovCentroid, 70)));                          % compute median macular pixel intensity
        scaledMaculaPI = double(maculaPI) - double(backgroundPI);                                               % scale macular pixel intensity by background intensity
        
        % Extract OD results
        ODstats          = stats(ODindex);
        ODcentroid       = [ODstats.Centroid(1), ODstats.Centroid(2)]; % centroid coordinates
        ODmajorLength    = ODstats.MajorAxisLength;                    % major Axis Length, not adjusted for magnification
        ODminorLength    = ODstats.MinorAxisLength;                    % minor Axis Length, not adjusted for magnification
        ODorientation    = abs(ODstats.Orientation);                   % orientation (absolute angle b/w x axis and OD major axis) 
        ODarea           = ODminorLength * ODmajorLength * pi/4;       % OD area based on the standard formula for ellipse, not adjusted for magnification

        % Save parameters to their respective columns in the result cell array.
        result{i+1, 2}  = fovCentroid(1);               
        result{i+1, 3}  = fovCentroid(2);               
        result{i+1, 4}  = scaledMaculaPI;               
        result{i+1, 5}  = ODcentroid(1);               
        result{i+1, 6}  = ODcentroid(2);               
        result{i+1, 7}  = ODmajorLength;
        result{i+1, 8} = ODminorLength;
        result{i+1, 9} = ODarea;
        result{i+1, 10} = ODorientation;
    end

    % Only compute OD-foveal distance and angle if OD and fovea masks are not empty
    if cc.NumObjects ~= 0 
        % Compute EUCLIDIAN DISTANCE b/w OD centroid & fovea centroid
        ODfovDist      = sqrt(sum((ODcentroid - fovCentroid) .^2)); 
    
        % Vertical angle between the disc and macula, i.e. angle
        % between the horizontal midline passing through the centroid
        % of the disc & the centroid of the macula.
        ODfoveaAngle = vert_angle(ODcentroid, fovCentroid);      % compute using Pythagorean theorem (see function below)
            
        % Save parameters to their respective columns in the result cell array.
        result{i+1, 11}  = ODfovDist;      
        result{i+1, 12}  = ODfoveaAngle;
    end
    
    % Note if mask was empty
    if cc.NumObjects == 0
        result{i+1, 13} = "failed";
    end
    
               
end

%% Save result (cell array) as csv
% write cell array to csv
path = fullfile(save_csv_path, 'ODfoveaResults.csv');
writecell(result, path);


%% Internal functions %%
% Function: takes centroid1 (optic disc) coordinate and centroid2 (macula) 
% coordinate, and returns disc-fovea angle which describes the vertical
% separation between the disc and fovea. Note that we compute the absolute
% difference between disc x and macula x coordinates to disregard the
% influence of right or left eye on the sign of the vertical angle. We want
% the sign of the computed vertical angle to reflect only the spatial
% relationship between the disc and macula in the Y plane.
% NEGATIVE vertical angle means disc is HIGHER than macula (rmb origin
% [0,0] starts in the top left corner!
function vert_angle = vert_angle(centroid1, centroid2)
x_distance = abs(centroid1(1) - centroid2(1)); 
y_distance = centroid1(2) - centroid2(2);
vert_angle = atand(y_distance / x_distance);

end








