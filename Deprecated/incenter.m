function centers = incenter(varargin)
%INCENTER Incenters of polygonal faces.
%   IC = INCENTER(FACES,VERTICES) returns the coordinates of the incenter
%   of each face in a face-vertex model.
%   
%   See also TRIANGULATION/INCENTER.

narginchk(1, 2)

[faces, vertices] = facevertex.fv(varargin{:});

centers = cell2mat(cellfun( ...
    @(indices) mean(vertices(indices, :), 1), ...
    num2cell(faces, 2), ...
    'UniformOutput', false));
