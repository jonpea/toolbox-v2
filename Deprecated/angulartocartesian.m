function xyz = angulartocartesian(angles, radii)
%ANGULARTOCARTESIAN Transform spherical to Cartesian coordinates.
% See also CARTESIANTOSPHERICAL, SPH2CART, CART2SPH

narginchk(1, 2)
if nargin < 2 || isempty(radii)
    radii = 1.0;
end

numangles = size(angles, 2);
assert(ismember(numangles, 1 : 2))
callbacks = {@polartocartesian, @sphericaltocartesian};

convert = callbacks{numangles};
xyz = convert(angles, radii);

function xy = polartocartesian(phi, r)
xy = [
    r .* cos(phi), ...
    r .* sin(phi)
    ];

function xyz = sphericaltocartesian(angles, r)
[theta, phi] = dealout(num2cell(angles, 1));
rsintheta = r .* sin(theta);
xyz = [
    rsintheta .* cos(phi), ...
    rsintheta .* sin(phi), ...
    r .* cos(theta)
    ];
