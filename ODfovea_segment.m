%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  Author: Fabian SL Yii                  %
%               Email: fabian.yii@ed.ac.uk                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc, clear all, close all;

%% Get all image names
filenames = dir(fullfile("images", "UKB", "fundus"));

%% Segment i-th image
i        = 1;
filename = filenames(i).name;
img      = imread(fullfile("images", "UKB", "fundus", filename));
imageSegmenter(img);

%% Save mask
imwrite(BW, fullfile("imageOutputs", "UKB", "ODfoveaMasks", filename));
clear BW; clear maskedImage;
display("done");


