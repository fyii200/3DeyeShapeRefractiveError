%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  Author: Fabian SL Yii                  %
%               Email: fabian.yii@ed.ac.uk                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc;
imageDir = "";
d        = readtable(fullfile("data", "UKB", "cleaned_data_long_MRI_cohort.csv"));
addpath(fullfile("matlabHelperFunctions", "getkey"));

% Fundus names 
fundusNames = d.fundus_V1;

% Create empty cell to save results
results = {};

% Create progress/wait bar
bar = waitbar(0, "Press 1 for good, 2 for usable, 3 for reject");
setappdata(bar,"canceling",0);

% Start quality assessment
for i = 1:length(fundusNames)
    
    fundusName = fundusNames(i);
    
    if fundusName ~= "NA"
        % Display fundus
        imagePath  = fullfile(imageDir, fundusName);
        image      = imread(imagePath);
        imshow(image);
        
        % Prompt user to respond by pressing 1, 2 or 3
        input = getkey(1,'non-ascii');
        if input=="1"
            input = "good";
        elseif input=="2"
            input = "usable";
        elseif input=="3"
            input = "reject";
        end

        % Save input
        results{i,1} = fundusName
        results{i,2} = input
        writetable(cell2table(results, "VariableNames",["fundus" "quality"]), "fundusQuality.csv")
        
        % Update waitbar
        waitbar(i/sum(fundusNames~="NA"));
    end
end

% Close waitbar
delete(bar);
msgbox("Finished!");
close all; 






