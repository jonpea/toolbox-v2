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

quarter = full/4;
y = quarter.*elfun.tri(x/quarter);

% Alternative implementation I: Needlessly complex
% 
% quarter = full/4;
% half = full/2;
% functions = {
%     @(x) x; % first quadrant - do nothing
%     @(x) half - x; % second quadrant
%     @(x) x - half; % third quadrant
%     @(x) full - x; % fourth quadrant
%     };
% 
% y = specfun.wrapcircle(x, full);
% quadrants = 1 + fix(y/quarter);
% y = reshape(indexedunary(functions, quadrants, y(:)), size(y));

% Alternative implementation II: Applies an element-wise
% transformation which is much slower than implementation I
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

end

% % -------------------------------------------------------------------------
% function result = indexedunary(functions, funofrow, x, varargin)
% %INDEXEDUNARY Evaluate functionals of one row-indexed argument.
% 
% narginchk(3, nargin)
% 
% import contracts.ndebug
% assert(ndebug || iscell(functions))
% if isscalar(funofrow)
%     funofrow = repmat(funofrow, size(x, 1), 1);
% end
% assert(ndebug || size(x, 1) == numel(funofrow))
% assert(ndebug || ndims(x) <= 4)
% 
% result = zeros(size(x, 1), 1);
%     function apply(fun, rows)
%         result(rows, :) = fun(x(rows, :, :, :), varargin{:});
%     end
% rowsoffun = invertIndices(funofrow, numel(functions));
% cellfun(@apply, functions(:), rowsoffun(:));
% 
% end
% 
% % -------------------------------------------------------------------------
% function inverted = invertIndices(indices, numgroups)
% shape = [numgroups, 1];
% indexrange = 1 : numel(indices);
% inverted = accumarray(indices(:), indexrange(:), shape, @(a) {a(:)});
% if isempty(indices)
%     % Corner case: If the input list is empty, then accumarray
%     % doesn't realize that the result should be a cell array (of empties)
%     inverted = repmat({zeros(0, 1)}, size(inverted));
% end
% end
