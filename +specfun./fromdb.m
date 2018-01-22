function p = fromdb(db, p0)
%FROMDB Conversion from decibel scale.
%   P = FROMDB(DB) satisfies TODB(P) == 10*LOG10(P) == DB.
%
%   P = FROMDB(DB,P0) satisfies
%         TODB(P,P0) == TODB(P)-TODB(P0) == DB.
%
%   See also TODB.

p = 10.^(db/10);

if nargin == 2
    p = p.*p0;
end
