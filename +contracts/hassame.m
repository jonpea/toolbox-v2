function tf = hassame(fun, varargin)
%HASSAME True where arguments have identical image.
%   HASSAME(@FUN, A1, A2, ..., AN) returns true if
%     FUN(A1), FUN(A2)), FUN(A3), ... FUN(AN) are identically equal.
%
%   Typical values for FUN are CLASS, SIZE, ISNAN, & NUMEL.
%
%   This function is not intended for large values of N.
%
%   See also ISEQUAL, ISEQUALN, CLASS, NUMEL, SIZE.

narginchk(2, nargin)

funfirst = fun(varargin{1}); % save duplicate evaluations
tf = true;
for arg = varargin(2 : end)
    tf = tf & isequal(funfirst, fun(arg{:}));
    if ~tf
        break
    end
end
