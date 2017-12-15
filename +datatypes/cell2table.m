function t = cell2table(c, row, column)
%CELL2TABLE Convert cell array to table.
%   DATATYPES.CELL2TABLE generalizes the capabilities of CELL2TABLE.
%
%   T = DATATYPES.CELL2TABLE(C) is equivalent to
%         T = CELL2TABLE(C(2:END,:),'VariableNames',C(1,:)).
%
%   T = DATATYPES.CELL2TABLE(C,'VariableNames',ROWIDX) specifies that
%   'VariableNames' should be extracted from row number ROWIDX of C.
%
%   T = DATATYPES.CELL2TABLE(C,'RowNames',COLIDX) specifies that
%   'RowNames' should be extracted from column number COLIDX of C.
%
%   See also CELL2TABLE.

narginchk(1, 3)
if nargin < 2
    row = 1;
end
if nargin < 3
    column = [];
end

namedVariables = logical(row);
namedRows = logical(column);

if namedVariables
    variableNames = c(row, :);
    if namedRows
        variableNames(column) = [];
    end
end

if namedRows
    rowNames = c(:, column);
    if namedVariables
        rowNames(row) = [];
    end
end

options = {};
if namedVariables
    c(row, :) = [];
    options(end + (1 : 2)) = {'VariableNames', variableNames};
end
if namedRows
    c(:, column) = [];
    options(end + (1 : 2)) = {'RowNames', rowNames};
end

t = cell2table(c, options{:});
