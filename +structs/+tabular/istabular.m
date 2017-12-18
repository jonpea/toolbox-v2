function result = istabular(t)
%ISTABULAR True for tabular structures
%   ISTABULAR(T) returns TRUE if T is a single tabular struct and FALSE
%   otherwise. A tabular struct is one in which all fields have the same
%   number of rows.
%
%   See also ISSTRUCT.

result = isscalar(t) && isstruct(t) && numel(heights(t)) <= 1;


