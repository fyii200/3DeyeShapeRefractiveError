function paramAxes = findAxes(rotationMatrix, interpret)
%findAxes  Find which axes (x, y, z) parameters A, B and C correspond to

% Convert all values in the rotation matrix into absolute values
R = abs(rotationMatrix);

% Extract the columns of the rotation matrix
Ra = R(:,1); % correspond to the vector defined by the (rotated) parameter A 
Rb = R(:,2); % correspond to the vector defined by the (rotated) parameter B
Rc = R(:,3); % correspond to the vector defined by the (rotated) parameter C

% Original axes
x  = [1, 0, 0];
y  = [0, 1, 0];
z  = [0, 0, 1];

%% Compute the angle between each of the three A, B, C parameters and x, y and z
%% axes to see which axis each (rotated) parameter lies closest to
axisNames = ["x", "y", "z"];
% Vector defined by the (rotated) parameter A
XAangle = rad2deg(acos(dot(x,Ra)));         % angle between x axis and parameter A
YAangle = rad2deg(acos(dot(y,Ra)));         % angle between y axis and parameter A
ZAangle = rad2deg(acos(dot(z,Ra)));         % angle between z axis and parameter A
[~,ind] = min([XAangle, YAangle, ZAangle]); % index corresponding to the smallest angle
paramAaxis = axisNames(ind);                % get axis to which parameter A lies closest

% Vector defined by the (rotated) parameter B
XBangle = rad2deg(acos(dot(x,Rb)));         % angle between x axis and parameter B
YBangle = rad2deg(acos(dot(y,Rb)));         % angle between y axis and parameter B
ZBangle = rad2deg(acos(dot(z,Rb)));         % angle between z axis and parameter B
[~,ind] = min([XBangle, YBangle, ZBangle]); % index corresponding to the smallest angle
paramBaxis = axisNames(ind);                % get axis to which parameter B lies closest

% Vector defined by the (rotated) parameter C
XCangle = rad2deg(acos(dot(x,Rc)));         % angle between x axis and parameter C
YCangle = rad2deg(acos(dot(y,Rc)));         % angle between y axis and parameter C
ZCangle = rad2deg(acos(dot(z,Rc)));         % angle between z axis and parameter C
[~,ind] = min([XCangle, YCangle, ZCangle]); % index corresponding to the smallest angle
paramCaxis = axisNames(ind);                % get axis to which parameter C lies closest

%% Return parameter axis for parameters [A, B, C]
% Set to 1 if the desired output is related to AL, width and height
if interpret
    % Note that X axis corresponds to axial length, Y corresponds to width and
    % Z corresponds to height
    paramAxes = [paramAaxis, paramBaxis, paramCaxis];
    paramAxes = strrep(paramAxes,"x", "AL");
    paramAxes = strrep(paramAxes,"y", "width");
    paramAxes = strrep(paramAxes,"z", "height");
else
    paramAxes = [paramAaxis, paramBaxis, paramCaxis];
end






















end