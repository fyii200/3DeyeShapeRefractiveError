%Demo file for imEquivalentEllipsoid fucntion.
%
%   output = demoImEquivalentEllipsoid(input)
%
%   Example
%   demoImEquivalentEllipsoid
%
%   See also
%
 
% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2019-08-28,    using Matlab 9.6.0.1072779 (R2019a)
% Copyright 2019 INRA - Cepia Software Platform.


%% Read and display 3D image

% read 3D data
metadata = analyze75info('brainMRI.hdr');
I = analyze75read(metadata);

% 3D display
% (used function from matImage library: 
%  https://github.com/mattools/matImage)
orthoSlices3d(I*3, [60 80 13], [1 1 2.5]);
axis equal; view(3); hold on;


%% Compute and display ellipsoid

% convert to binary data
bin = imclose(I > 0, ones([3 3 3]));

% compute equivalent ellipsoid, taking into account the spatial calibration
elli = imEquivalentEllipsoid(bin, [1 1 2.5]);

% display over previous image
drawEllipsoid(elli, 'FaceAlpha', 0.5);
