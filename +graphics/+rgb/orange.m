function rgb = orange(intensity)
%ORANGE RGB color code for orange.
%
%   For further information, see e.g. 
%     http://www.rapidtables.com/web/color/orange-color.htm
%
%   See also RGBGRAY.
if nargin < 1
    intensity = 0.5;
end
assert(0.0 <= intensity && intensity <= 1.0)
lower = 69; % for "orange-red"
upper = 215; % for "gold"
green = lower + intensity*(upper - lower);
rgb = [255, green, 0]/255;
