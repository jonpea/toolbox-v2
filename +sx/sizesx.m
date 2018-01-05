function result = sizesx(varargin)
%SIZESX Size of the result of elementwise operation.
%   SIZESX(A,B) is the size of the result of any elementwise operation
%   between arrays A and B, e.g. PLUS, TIMES etc.
%
%   SIZESX(A1,A2,...,AN) returns the result of any N-ary elementwise
%   operation between arrays A1, A2, ... AN.
%
%   SIZESX(A) returns SIZE(A).
%
%   See also SIZE.

narginchk(1, nargin)
assert(contracts.ndebug || sx.iscompatible(varargin{:}))
sizes = sx.sizetable(varargin{:}); % sizes along each row
result = max(sizes, [], 1); % maximum in each column
