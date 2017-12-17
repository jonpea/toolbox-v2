function result = tabularfun(fun, varargin)

narginchk(2, nargin)

assert(isfunction(fun) || isstruct(fun))
assert(all(cellfun(@isstruct, varargin)))

argumentnames = fieldnames(varargin{1});
samecolumnnames = @(s) isequal(fieldnames(s), argumentnames);
assert(all(cellfun(samecolumnnames, varargin)))

% Check argument tables have conforming dimensions
tablesize = tabularsize(varargin{1});
samenumrows = @(s) tabularsize(s) == tablesize;
assert(all(cellfun(samenumrows, varargin)))

if isfunction(fun)
    % Replicate single function across all column headings
    fun = cell2struct(repmat({fun}, size(argumentnames)), argumentnames);
end

% Check that function fields are a subset of argument fields
assert(all(ismember(fieldnames(fun), argumentnames)))

fundefs = struct2cell(fun);
funnames = fieldnames(fun);

getfuncolumns = @(s) tabularcolumns(s, funnames);
varargin = cellfun(getfuncolumns, varargin, 'UniformOutput', false);

% Table with columns "function", "argument 1", "argument 2" etc.
% and rows corresponding to the field names of the functions.
funandarguments = [fundefs(:), struct2cell(vertcat(varargin{:}))];

% Convert table to struct with one field for each row
tuples = cell2struct(num2cell(funandarguments, 2), funnames, 1);

% For each tuple, apply the function in the first 
% column on the arguments in subsequent columns
result = structfun( ...
    @(tuple) feval(tuple{:}), ...
    tuples, ...
    'UniformOutput', false);
