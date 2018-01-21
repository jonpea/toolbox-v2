function result = isequalfp(actual, expected, tol)
%ISEQUALFP True if arrays are numerically equal in finite precision.
% ISEQUALFP(A,B,TOL) returns true if every element of
%     ABS(A - B) < TOL.*(ABS(B) + 1)
% is true. TOL may have the same size as A and B or it may be scalar.
%
% NB: Arrays A and B should have identical size and class; unlike
% ISEQUAL, ISEQUALFP will not silently return false if these differ.
%
% ISEQUALFP(A,B) uses 10*EPS(class(B)) for TOL.
%
% See also ISEQUAL, EPS.

narginchk(2, 3)

if nargin < 3 || isempty(tol)
    tol = 10*eps(class(expected));
end

assert(isequal(class(actual), class(expected)))
assert(isequal(size(actual), size(expected)))
assert(isscalar(tol) || isequal(size(tol), size(expected)))

% Ignore nan's common to both arrays
mask = isnan(actual) & isnan(expected);

scale = abs(expected) + ones('like', expected);
comparisons = abs(actual - expected) < tol.*scale;
result = all(comparisons(~mask));
