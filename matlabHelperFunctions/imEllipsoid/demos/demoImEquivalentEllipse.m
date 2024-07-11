% Demo file for using function imEquivalentEllipse
%
%   Syntax
%   demoImInertiaEllipse
%   The demo runs automatically.
%
%   Example
%   demoImInertiaEllipse
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2011-05-09,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.


%% Image segmentation

% read image
img = imread('rice.png');
figure; imshow(img);

% remove background (White top hat)
bg = imopen(img, ones(30, 30));
img2 = img - bg;

% image binarisation, and remove particles touching border
bin = img2>50;
bin = imclearborder(bin, 4);
figure; imshow(bin);

% compute image labels, using minimal connectivity
lbl = bwlabel(bin, 4);
nLabels = max(lbl(:));

% display label image
rgb = label2rgb(lbl, jet(nLabels), 'w', 'shuffle');
figure; imshow(rgb);


%% Compute equivalent ellipses

% call the function
ellipses = imEquivalentEllipse(lbl);

% display result
hold on;
drawEllipse(ellipses, 'linewidth', 2, 'color', 'b');

