function result = tabularvertcat(structs, heterogeneous)
%TABULARVERTCAT Vertical concatenation of tabular structs.
% See also TABULARHORZCAT, VERTCAT, STRUCT2TABLE, TABLE2STRUCT.

% Preconditions
narginchk(1, 2)
if nargin < 2
    heterogeneous = false; % by default, enforce homogeneity of each column
end
assert(isstruct(structs))
assert(islogical(heterogeneous))

% Basic support for heterogeneous columns e.g. {':', [1,2,5], []}
sizes = arrayfun(@tabularsize, structs);
if heterogeneous
    assert(all(sizes == 1), ...
        'All elements must be singleton if heterogeneous')
end

% Column names
names = fieldnames(structs);

% Singleton entries will not, in general, be preserved after vertical
% concatenation (unless we attempt to verify that singleton fields in all
% elements are identical).
structs = arrayfun(@tabularnormalize, structs);

% Combine the field values for each column
values = cellfun(@extract, names, 'UniformOutput', false);
    function values = extract(name)
        values = reshape({structs.(name)}, [], 1);
        oldvalues = values;
        if all(cellfun(@ischar, values))
            % Special case: Required to cat variable-length strings
            temporary = cellfun( ...
                @(s) num2cell(s, 2), values, 'UniformOutput', false);
            values = vertcat(temporary{:});
            return
            %values = cellfun(@cellify, values, 'UniformOutput', false);
        end
        if ishomogeneous(values)
            values = vertcat(values{:});
        else
            assert(heterogeneous, ...
                'Column %s does not have homogeneous rows', name)
            values = values(:); % heterogeneous singletons
        end
    end

% Form a single new tabular struct from the concatenated fields
result = cell2struct(values, names, 1);

end

% -------------------------------------------------------------------------
function result = isstringfield(x)
% True if argument is traditional (char-based) string or cellstr.
result = ischar(x) || iscellstr(x);
% result = (ischar(x) && isrow(x)) || iscellstr(x);
end

% -------------------------------------------------------------------------
function s = cellify(s)
% Convert non-cell to cell
if ~iscell(s)
    s = {s};
end
end

% -------------------------------------------------------------------------
function result = ishomogeneous(c)
assert(iscell(c))
if isempty(c)
    result = true;
    return
end
type1st = class(c{1});
shape1st = size(c{1});
    function result = matchesfirst(x)
        shape = size(x);
        result = isa(x, type1st) && ...
            isequal(shape(2 : end), shape1st(2 : end));
    end
result = all(cellfun(@matchesfirst, c));
end
