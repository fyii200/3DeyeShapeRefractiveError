%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                         %
%                  Author: Fabian SL Yii                  %
%               Email: fabian.yii@ed.ac.uk                %
%                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc, clear all, close all;
root  = "/Users/fabianyii/Library/CloudStorage/OneDrive-UniversityofEdinburgh/Projects/eyeShape";


%% Get image names
filenames = dir(fullfile(root, "images", "UKB", "fundus"));
i = 1;
filename = filenames(i).name;
img = imread(fullfile(root, "images", "UKB", "fundus", filename));
imageSegmenter(img);

%% Save mask
imwrite(BW, fullfile(root, "imageOutputs", "UKB", "ODfoveaMasks", filename));
clear BW; clear maskedImage;
display("done");


