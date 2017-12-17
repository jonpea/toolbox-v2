function result = iscolumnar(t)
%ISCOLUMNAR True for tabular structures
%   ISCOLUMNAR(T) returns TRUE if T is a single tabular struct and FALSE
%   otherwise. A tabular struct is one in which all fields have the same
%    number of rows.
%
% See also ISSTRUCT.

result = ...
    isscalar(t) && ...
    isstruct(t) && ...
    isuniformheight(t);

function result = isuniformheight(t)
heights = structfun(@nrows, t);
result = numel(unique(heights)) <= 1;

function n = nrows(a)
n = size(a, 1);
