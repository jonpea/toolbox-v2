function t = head(t, k)
%HEAD Return the first few rows of a tabular struct.
%   HEAD(T) returns the first eight rows of tabular struct T.
%   HEAD(T,K) returns the first K rows of tabular struct T.
%
%   See also TAIL, TABULAR/TAIL, TALL/HEAD.

import datatypes.struct.tabular.height
import datatypes.struct.tabular.rows

if nargin == 1
    k = 8; % consistent with table/head
end

t = rows(t, 1 : min(height(t), k));
