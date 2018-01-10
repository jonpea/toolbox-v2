function [faces, vertices] = linestofacevertex(varargin)
%LINESTOFACEVERTEX Face-vertex representation from line segments.
% [F,V]=LINESTOFACEVERTEX(X1,Y1,X2,Y2) returns the face-vertex
% representation of a set of line segments given by 
%   {[(X1(i), Y1(i)), (X2(i), Y2(i))]: i = 1, 2, ... }.
% The four arguments must be column vectors of identical length.
% Alternatively, LINESTOFACEVERTEX([X1 Y1],[X2 Y2]) and 
% and LINESTOFACEVERTEX([X1 Y1 X2 Y2]) work in the same way.
% See also POLY2FV in the Mapping Toolbox.

narginchk(1, 4)
assert(ismember(nargin, [1 2 4]))

xy1xy2 = [varargin{:}];
[numlines, numcoordinates] = size(xy1xy2);
assert(numcoordinates == 4, ...
    'Arguments must concatenate to a matrix with 4 columns')

vertices = reshape(xy1xy2.', 2, []).';
faces = reshape(1 : 2*numlines, 2, []).';

[vertices, ~, map] = unique(vertices, 'rows');
faces(:) = map(faces(:));

if nargout < 2
    % This struct is compatible with PATCH
    faces = struct('Faces', faces, 'Vertices', vertices);
end
