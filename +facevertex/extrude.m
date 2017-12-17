function varargout = extrude(varargin)

import contracts.unreachable
import datafun.reduce
import facevertex.cat
import facevertex.fv

narginchk(2, 3)

[faces, vertices] = fv(varargin{1 : end - 1});
span = varargin{end};

assert(ismember(size(span, 1), [1, size(faces, 1)]), ...
    'Final argument must be a row vector or have one row for each facet.')
assert(ismember(size(span, 2), 1 : 2), ...
    'Final argument must be a matrix with one or two columns.')
assert(size(vertices, 2) == 2, ...
    'The array of vertex coordinates must have two columns.')

if iscolumn(span)
    % Lower limit defaults to 0.0
    span = [zeros(size(span)), span];
end

if isrow(span)
    % Replicate a single span across all faces
    span = repmat(span, size(faces, 1), 1);
end

[uniqueSpan, ~, uniqueIndex] = unique(span, 'rows');
    function [model, map] = process(index)
        map = find(uniqueIndex == index);
        model = extrudeOnce( ...
            faces(map, :), vertices, ...
            uniqueSpan(index, 1), uniqueSpan(index, 2));
    end
[models, maps] = arrayfun( ...
    @process, 1 : size(uniqueSpan, 1), 'UniformOutput', false);

varargout = {
    cat(models{:}) ...
    vertcat(maps{:}) ...
    };

end

% -------------------------------------------------------------------------
function [faces, vertices] = extrudeOnce(faces, vertices, lower, upper)
%EXTRUDEPLAN Extruison of a 2D plan in face-vertex repsentation.
% [FF,VV]=EXTRUDEPLAN(F,V,LOWER,UPPER) extrudes a set of 2D line segments
% with face-vertex representation F-V into a set of 3D quadrilaterals with
% representation FF-VV spanning the range from LOWER to UPPER in the
% vertical direction.
% EXTRUDEPLAN(F,V,HEIGHT) with non-zero scalar HEIGHT is equivalent
% to EXTRUDEPLAN(F,V,0.0,HEIGHT).
% See also EXTRUDEPATCH

narginchk(2, 4)

switch nargin
    case 2 % default span
        lower = 0.0;
        upper = 1.0;
    case 3 % given height
        assert(lower ~= 0)
        upper = lower;
        lower = 0.0;
end

assert(size(faces, 2) == 2)
assert(isscalar(lower))
assert(isscalar(upper))
assert(lower ~= upper)

if upper < lower
    [lower, upper] = deal(upper, lower);
end

numvertices = size(vertices, 1);

vertices = [
    vertices, repmat(lower, numvertices, 1);
    vertices, repmat(upper, numvertices, 1);
    ];

faces = [
    faces, ...
    fliplr(faces) + numvertices
    ];

if nargout == 1
    faces = struct('Faces', faces, 'Vertices', vertices);
end

end
