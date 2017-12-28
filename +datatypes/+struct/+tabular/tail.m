function t = tail(t, k)
%TAIL Return the last few rows of a tabular struct.
%   TAIL(T) returns the last eight rows of tabular struct T.
%   TAIL(T,K) returns the last K rows of tabular struct T.
%
%   See also TABLE/HEAD, TALL/TAIL.

import datatypes.struct.tabular.height
import datatypes.struct.tabular.rows

if nargin == 1
    k = 8;
end

n = height(t);
t = rows(t, max(1, n - k + 1) : n);
