function varargout = uncat(a, varargin)
%COLS Array columns.
%   [C1,..,CM] = UNCAT(A,DIM) with array A and scalar DIM
%   satisfy the relationship ISEQUAL(CAT(DIM,C1,..,CM), A).
%
%   UNCAT(A) applies along the first non-singleton dimension of A.
%
%   See also CAT.

% Note to Maintainer:
% The names "split" and "slice" seem like natural alternatives,
% but are already utilized in MATLAB standard library.

narginchk(1, 2)

dim = sx.leaddim(a, varargin{:});

varargout = num2cell(a, setdiff(1 : ndims(a), dim));
