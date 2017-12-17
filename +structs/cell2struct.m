function table = cell2struct(varargin)
%CELL2STRUCT Convert cell array to columnar struct.
%   S = CELL2STRUCT([HEADER; BODY]}) where HEADER is a CELLSTR and BODY is
%   a cell array returns a struct pairing each element of HEADER with each
%   column of BODY. S is equivalant to
%      STRUCT(HEADER{1},BODY(:,1),HEADER{2},BODY(:,2),...).
%
%   S = CELL2STRUCT(HEADER,BODY) is an equivalent alternative.
%
%   See also CELL2STRUCT.

narginchk(1, 2)

switch nargin
    case 1
        % Invoked with "({header; body})"
        data = varargin{:};
        assert(iscell(data), 'Expected a cell array.')
        header = data(1, :);
        body = num2cell(data(2 : end, :), 1);
    case 2
        % Invoked with "(header, body)"
        [header, body] = varargin{:};
end

assert(ismatrix(body))
assert(iscellstr(header))
assert(all(cellfun(@ishomogeneous, body)), ...
    'The elements of each column must be type homogeneous')

body = cellfun(@compress, body, 'UniformOutput', false);
table = builtin('cell2struct', body, header, 2);

% -------------------------------------------------------------------------
function result = ishomogeneous(c)
types = cellfun(@class, c(:), 'UniformOutput', false);
result = numel(unique(types)) <= 1;

% -------------------------------------------------------------------------
function a = compress(a)
if ~iscellstr(a)
    % Note: CELL2MAT does not support cell arrays containing
    % cell arrays or objects (including enumerations)
    a = vertcat(a{:});
    %a = cell2mat(a);
end
