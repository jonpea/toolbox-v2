function result = csprintf(format, varargin)
%CSPRINTF Write formatted data to cell array of character vectors.
% CS = CSPRINTF(FORMAT,A,B,...) applies FORMAT to corresponding
% elements of arrays A, B, ... and any additional array arguments in
% column order, and returns the results as a cell array CS.
% FORMAT can be a character vector or a string scalar.
% The data type of the elements of CS is the same as the data type 
% of FORMAT.
%
% NB: Character vectors that are to be treated as individual strings
% should be wrapped in braces i.e. passed as scalar cell arrays.
%
% >> csprintf('Order #%d: Value $%g, (%s)', [1, 2, 3], [7.5, 3.2, 1.4], {datestr(now)})
% ans =
%   3×1 cell array
%     'Order #1: Value $7.5, (09-Aug-2017 09:12:55)'
%     'Order #2: Value $3.2, (09-Aug-2017 09:12:55)'
%     'Order #3: Value $1.4, (09-Aug-2017 09:12:55)'
%
% See also SPRINTF, CELLSTR, ISCELLSTR.

tocell = {'UniformOutput', false}; % helper

lengths = cellfun(@numel, varargin);
uniquelengths = unique(lengths);

% Ensure that arguments have consistent length
assert(ismember(numel(uniquelengths), 1 : 2), ...
    'Non-scalar arguments must have identical numbers of elements')

% Expand singletons
length = max(uniquelengths);
issingleton = find(lengths == 1);
varargin(issingleton) = cellfun( ...
    @(x) repmat(x, length, 1), ...
    varargin(issingleton), ...
    tocell{:});

% Ensure all data arrays have uniform (e.g. vertical) orientation
varargin = cellfun(@cellColumn, varargin, tocell{:});

result = cellfun( ...
    @(varargin) sprintf(format, varargin{:}), ...
    varargin{:}, ...
    tocell{:});

function x = cellColumn(x)
% Presents the input as a cell array in column order
x = x(:);
if ~iscell(x)
    x = num2cell(x);
end
