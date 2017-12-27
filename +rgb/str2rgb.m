function rgb = str2rgb(str, intensity)
%STR2RGB Convert color string to associated RGB code.
%   See also COLORSPEC, IND2RGB, HSV2RGB.

narginchk(1, 2)

if nargin < 2
    intensity = 1.0;
end

assert(isscalar(intensity))
assert(isnumeric(intensity))
assert(0 <= intensity && intensity <= 1.0)

% Special case:
% Both 'black' and 'blue' start with 'b';
% Here, we follow MATLAB's official abbreviations.
switch lower(str)
    case 'b'
        str = 'blue';
    case 'k'
        str = 'black';
end

map = struct( ...
    'yellow', [1 1 0], ...
    'magenta', [1 0 1], ...
    'cyan', [0 1 1], ...
    'red', [1 0 0], ...
    'green', [0 1 0], ...
    'blue', [0 0 1], ...
    'white', [1 1 1], ...
    'black', [0 0 0]);

str = validatestring(str, fieldnames(map));
rgb = intensity .* map.(str);
