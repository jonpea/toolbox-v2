function [faces, vertices] = gridplan(x, y)
% GRIDPLAN Face-vertex representation of plan with regular grid structure.
% [FACES, VERTICES] = GRIDPLAN(XTICKS, YTICKS) with a given pair of grid
% vectors XTICKS and YTICKS returns a face-vertex representation of the
% plan of a regular grid. 
%
% The example below shows that:
% - The minimal number of faces is employed.
% - VERTICES contains no duplicate rows corresponding to corner vertices.
%
% Example:
% >> [faces, vertices] = gridplan(1 : 2, 10 : 13)
% faces =
%      1     4
%      5     8
%      1     5
%      2     6
%      3     7
%      4     8
%
% vertices =
%      1    10
%      1    11
%      1    12
%      1    13
%      2    10
%      2    11
%      2    12
%      2    13
%
% >> patch('Faces', faces, 'Vertices', vertices), axis equal, axis tight
%
% See also EXTRUDEPLAN, NDGRID.

narginchk(2, 2)

assert(isvector(x) && issorted(x) && 2 <= numel(x))
assert(isvector(y) && issorted(y) && 2 <= numel(y))

% Vertex coordinates
[x1, y1] = ndgrid(x, y([1, end]));
[x2, y2] = ndgrid(x([1, end]), y);
vertices = [
    x1(:), y1(:);
    x2(:), y2(:);
    ];

% Vertex indices of each face
index = @(x) reshape(1 : numel(x), size(x));
i1 = index(x1);
i2 = index(x2) + numel(x1);
faces = [
    i1;
    i2';
    ];

% Remove duplicates vertices at corners
[vertices, ~, map] = unique(vertices, 'rows');
faces(:) = map(faces(:));
