function bounds = bbox(points, padfun)
%BBOX Axis-aligned bounding box.
%   B = BBOX([X Y]) where X and Y are numeric column vectors 
%   returns a 1x4 array [MIN(X),MAX(X),MIN(Y),MAX(Y)].
%
%   B = BBOX([X,Y,Z]) where X, Y, and Z are numeric column vectors
%   returns the 1x6 array [MIN(X),MAX(X),MIN(Y),MAX(Y),MIN(Z),MAX(Z)].
%
%   B = BBOX(P, FRAC) where P is a numeric matrix with 2 or 3 columns 
%   and FRAC is numeric scalar or numeric array with SIZE(P,2) elements 
%   returns a bounding box extended by a relative amount FRAC in each 
%   direction.
%
%   B = BBOX(P, @FRACFUN) uses FRAC=FRACFUN(WIDTHS) where WIDTHS is a 
%   1x2 or 1x3 array containing the width in each direction.
%
%   Example: Add 30% margin around a scatter plot of random points
%   >> points = rand(20, 2);
%   >> plot(points(:, 1), points(:, 2), 'x')
%   >> hold on
%   >> axis(graphics.bbox(points, 0.3))
%
%   See also AXES, MIN, MAX.

if nargin < 2
    padfun = 0.1;
end
if isnumeric(padfun)
    padfun = @(widths) padfun'.*widths;
end
assert(ismember(size(points, 2), 2 : 3))
lower = min(points, [], 1);
upper = max(points, [], 1);
delta = padfun(upper - lower);
bounds = reshape([lower - delta; upper + delta], 1, []);
