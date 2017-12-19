function varargout = rotatepoints(x, y, z, azel, alpha, origin)
%ROTATEPOINTS Rotate about specified origin.
%   See also ROTATE, SPH2CART, CART2SPH.

% This function is a small modification of ROTATE:
%   Copyright 1984-2012 The MathWorks, Inc.

import contracts.issame

narginchk(5, 6)

if nargin < 6
    mid = @(a) 0.5*(min(a(:)) + max(a(:))); % mid-point
    origin = [mid(x), mid(y), mid(z)];
end

assert(issame(@size, x, z))
assert(ismember(numel(azel), 2 : 3))
assert(isscalar(alpha))
assert(numel(origin) == 3)

xyz = bsxfun(@plus, origin(:)', ...
    [
    x(:) - origin(1), ...
    y(:) - origin(2), ...
    z(:) - origin(3)
    ]*rotor3d(azel, alpha));

shape = size(x);
newxyz = [
    x(:) - origin(1) ...
    y(:) - origin(2) ...
    z(:) - origin(3) ...
    ];
newxyz = newxyz*rot;
newx = origin(1) + reshape(newxyz(:,1), shape);
newy = origin(2) + reshape(newxyz(:,2), shape);
newz = origin(3) + reshape(newxyz(:,3), shape);


varargout = cellfun( ...
    @(a) reshape(a, size(x)), ...
    num2cell(xyz, 1), ...
    'UniformOutput', false);
