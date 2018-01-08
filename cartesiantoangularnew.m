function varargout = cartesiantoangularnew(xyz)
%CARTESIANTOANGULAR Transform Cartesian to spherical coordinates.
% See also CART2SPH, SPH2CART

narginchk(1, 1)
nargoutchk(0, 2)

numdimensions = size(xyz, 2);
if numdimensions ~= 2
    [];
end
assert(ismember(numdimensions, 2 : 3))

callbacks = {@convert2d, @convert3d};
convert = callbacks{numdimensions - 1};
[varargout{1 : max(1, nargout)}] = convert(xyz);

% -------------------------------------------------------------------------
function [angle, radius] = convert2d(xy)
[x, y] = dealcell(num2cell(xy, 1));
angle = atan2(y, x); % azimuth
if nargout == 2
    radius = hypot(x, y);
end

% -------------------------------------------------------------------------
function [angles, radius] = convert3d(xyz)
[x, y, z] = dealcell(num2cell(xyz, 1));
hypotxy = hypot(x, y);
angles = [
    atan2(y, x), ... % azimuth
    0.5*pi - atan2(z, hypotxy) % inclination
    ];
if nargout == 2
    radius = hypot(hypotxy, z);
end

% -------------------------------------------------------------------------
function varargout = dealcell(c)
assert(iscell(c))
varargout = c;
