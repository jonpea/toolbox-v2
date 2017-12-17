function t = tabulartail(t, k)
%TABULARTAIL Return the last few rows of a tabular struct.
% TABULARTAIL(T) returns the last eight rows of tabular struct T.
% TABULARTAIL(T,K) returns the last K rows of tabular struct T.
% See also TABULARHEAD/HEAD,, TALL/TAIL.
if nargin == 1
    k = 8;
end
n = tabularsize(t);
t = tabularrows(t, max(n - k + 1) : n);
