function p = fromdb(db, p0)
%FROMDB Recover power from decibel value.
% P = FROMDB(DB) satisfied 10*LOG10(P) == DB.
% See also FROMDB.
p = 10.^(db/10);
if nargin == 2
    p = p.*p0;
end
    