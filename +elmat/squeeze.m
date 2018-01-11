function a = squeeze(a, dim)
%SQUEEZE Remove singleton dimensions.
%   B = SQUEEZE(A) returns an array B with the same elements as
%   A but with all the singleton dimensions removed.  A singleton
%   is a dimension such that size(A,dim)==1.  2-D arrays are
%   unaffected by squeeze so that row vectors remain rows.
%
%   SQUEEZE(A,DIMS) specifies which dimensions of A are to be squeezed.
%   Each dimension specified in DIMS must be singleton.
%
%   Examples:
%   >> squeeze(rand(2,1,3)) % is 2-by-3
%
%   See also SHIFTDIM.

narginchk(1, 2)

if nargin < 2
    % Defaults to behavior of MATLAB's built-in squeeze
    a = squeeze(a);
    return
end

shape = size(a);

% Drop redundant trailing dimensions (automatically squeezed)
dim(ndims(a) < dim) = [];

% Verify that non-redundant dimensions are actually singleton
if any(shape(dim) ~= 1)
    error(contracts.msgid(mfilename, 'NonSingleton'), ...
        'A must be singleton in all specified dimensions.')
end

% Drop spedified singletons
shape(dim) = [];

% Ensure result has at least two dimensions
shape(end + 1 : 2) = 1;

a = reshape(a, shape);
