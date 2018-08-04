function rowaggregate = reduce(fun, varargin)
%REDUCE Cell rowaggregate of face-vertex representation.

import contracts.ndebug
import datatypes.isfunction

narginchk(2, 3)
assert(isfunction(fun))

[faces, vertices, varargin] = parseFaceVertexPair(varargin{:});

facepoints = reshape( ...
    vertices(faces', :)', ...
    size(vertices, 2), ... % one column per dimension
    size(faces, 2), ...    % one row per vertex in each face
    []);                   % one slice per face
facepoints = permute(facepoints, [2 1 3]);

% By default, the function is applied along the
% first dimension, consistent with mean/min/max
rowaggregate = fun(facepoints, varargin{:});
rowaggregate = reshape(rowaggregate, [], size(faces, 1))';

% Post-conditions
assert(ndebug || size(rowaggregate, 1) == size(faces, 1))
assert(ndebug || size(rowaggregate, 2) == size(vertices, 2))
