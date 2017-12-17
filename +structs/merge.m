function result = merge(varargin)
%MERGE Concatenate structure arrays.
%   S = MERGE(S1,S2) produces a structure array S whose fields
%   are the union of the fields of structure arrays S1 and S2.
%   If S1 and S2 share field names, the value is taken from S1.
%   S preserves the ordering of field names in S1 and S2.
%
%   MERGE(S1,S2,...,SN) merges the fields of an arbitrary number of
%   structure arrays. Fields with common names are taken from the first
%   instance in the argument list.
%
% See also CAT, STRUCT, TABLE/HORZCAT.

narginchk(1, nargin)
assert(all(cellfun(@isstruct, varargin)))

% Extract and aggregate field names and values
% Notes:
% (1) Reassignment of varargin keeps m-lint happy in the nested function.)
% (2) At this point, one could use 'fliplr(varargin)" to reverse the
%     cell array - but not the contents of each element - so later
%     entries take precedence in the call to unique(), below.
structs = varargin;
    function result = combine(fun)
        temporary = cellfun(fun, structs, 'UniformOutput', false);
        result = cat(1, temporary{:});
    end
names = combine(@fieldnames);
values = combine(@struct2cell);

% Retain fields from subset with unique names
% NB: Common names are taken from the earliest instance
[uniquenames, indices] = unique(names);

% Re-sort names to preserve original field order
[indices, permutation] = sort(indices);
uniquenames = uniquenames(permutation, :);

% Drop duplicate field values
subscripts = substruct('()', [ ...
    {indices}, ... % subset of rows
    repmat({':'}, 1, ndims(values) - 1) % all other subscript slots
    ]);

% Recombine field names and values
result = cell2struct(subsref(values, subscripts), uniquenames, 1);

end
