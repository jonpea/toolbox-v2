function result = size(varargin)
%SIZE Size of the result of elementwise operation.
%   SX.SIZE(A,B) is the size of the result of any elementwise operation
%   between arrays A and B, e.g. PLUS, TIMES etc.
%
%   SX.SIZE(A1,A2,...,AN) returns the result of any N-ary elementwise
%   operation between arrays A1, A2, ... AN.
%
%   SX.SIZE({A},..) returns SIZE(A,..).
%
%   See also SIZE.

narginchk(1, nargin)

dim = []; % default "dimension"
if iscell(varargin{1})
    assert(nargin <= 2)
    if nargin == 2
        dim = varargin{2};
        assert(isnumeric(dim) && isscalar(dim) && fix(dim) == dim)
    end
    varargin = varargin{1};
end

if ~sx.iscompatible(varargin{:})
    error(contracts.msgid(mfilename, 'IncompatibleArrays'), ...
        'Arguments are incompatible with singleton expansion.')
end

sizes = sx.sizetable(varargin{:}); % sizes along each row
result = max(sizes, [], 1); % maximum in each column

if isempty(dim)
    % Return "entire shape" when no dimension is specified
    return
end

if dim <= numel(result)
    % Specified dimension within "1 : ndims"
    result = result(dim);
else
    % Unit excess dimensions e.g. size(eye(5), 3) == 1
    result = 1;
end
