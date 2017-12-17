function t = tabularhead(t, k)
%TABULARHEAD Return the first few rows of a tabular struct.
% head(T) returns the first eight rows of tabular struct T.
% head(T,K) returns the first K rows of tabular struct T.
% See also TABULAR/TAIL, TALL/HEAD.

import structs.height
import structs.rows

if nargin == 1
    k = 8;
end

t = rows(t, 1 : min(height(t), k));
