function g = grid3(x, y, z)

import points.fullgrid.fullgrid

assert(ismember(nargin, [1, 3]))
if nargin == 1
    [y, z] = deal(x);
end

g = fullgrid(x, y, z);
