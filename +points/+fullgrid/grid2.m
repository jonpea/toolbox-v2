function g = grid2(x, y)

import points.fullgrid.fullgrid

narginchk(1, 2)

if nargin < 2
    y = x;
end

g = fullgrid(x, y);
