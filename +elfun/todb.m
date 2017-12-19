function db = todb(a, b)
%TODB Convert to decibel scale.
%   TODB(P) returns 10*LOG10(P).
%
%   TODB(P,Q) returns TODB(P./Q) == 10*LOG10(P./Q) == TODB(P)-TODB(Q).
% 
%   See also FROMDB.

narginchk(1, 2)

if nargin == 2
    a = a./b;
end

db = 10*log10(a);
