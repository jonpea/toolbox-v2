function y = wrapquadrant(x, full)
%WRAPQUADRANT Wraps to principle value on first quadrant.
% WRAPQUADRANT(X, L) maps angles on [0, inf) to the first quadrant [0, L].
%
% Examples:
% >> wrapquadrant([
%      0    45    90    91   180   270   360   365    -5], 360)
% ans =
%      0    45    90    89     0    90     0     5     5
%
% See also WRAPINTERVAL.

narginchk(1, 2)

if nargin < 2 || isempty(full)
    full = 2*pi;
end

assert(isscalar(full))

quarter = full/4;
half = full/2;
functions = {
    @(x) x; % first quadrant - do nothing
    @(x) half - x; % second quadrant
    @(x) x - half; % third quadrant
    @(x) full - x; % fourth quadrant
    };

y = elfun.wrapcircle(x, full);
quadrants = 1 + fix(y/quarter);
y = reshape(funfun.indexedunary(functions, quadrants, y(:)), size(y));

% Alternative implementation: Applies an element-wise
% transformation which is much slower
% e.g. 1.6 sec vs 0.1 sec for 1,000,000 elements
%
%     function x = wrapquadrantscalar(x)
%         switch fix(x/quarter)
%             case 1, x = half - x;
%             case 2, x = x - half;
%             case 3, x = full - x;
%             case 4, x = 0;
%         end
%     end
% y = arrayfun(@wrapquadrantscalar, wrapcircle(x, full));
