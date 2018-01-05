function db = todb(a, b)
%TODB Convert to decibel scale.
% TODB(P) returns 10*LOG10(P).
% TODB(P, Q) returns 10*LOG10(P./Q).
% See also FROMDB.
if nargin == 2
    a = a./b;
end
db = 10*log10(a);
