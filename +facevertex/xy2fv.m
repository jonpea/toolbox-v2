function varargout = xy2fv(varargin)
%XY2FV Convert vertex lists to face-vertex representation.
%   [FACES,VERTICES] = FC2XY(X,Y) returns the face-vertex representation
%   of a polygon complex given as vertex lists:
%   [X(i,j),Y(i,j)] are the coordinate of vertex i of polygon j;
%   FACES(j,:) is the connectivity list for polygon j; and
%   VERTICES(i,1:2) are the coordinates of vertex i.
%
%   [FACES,VERTICES] = FC2XY(X,Y,Z) applies to a 3-D complex.
%
%      Faces corresponds to 'Faces'
%   Vertices corresponds to 'Vertices'
%          X corresponds to 'XData'
%          Y corresponds to 'YData'
%          Z corresponds to 'ZData'
%
%   See the reference page on Patch Properties for further details.
%
%   See also PATCH, FV2XY.

import contracts.issame
import contracts.ndebug
import datafun.reduce
import facevertex.fv

narginchk(2, 4)
if ischar(varargin{end})
    mask = varargin{end};
    varargin(end) = [];
else
    mask = 'duplicate';
end
assert(ndebug || issame(@size, varargin{:}))
assert(ndebug || issame(@isnan, varargin{:}))

mask = validatestring(mask, {'duplicate', 'nan'}, mfilename, 'mask');

% Connectivity lists
shape = size(varargin{1});
faces = reshape(1 : prod(shape), shape);

% Mark duplicate trailing vertices with NaN
if strcmpi(mask, 'nan')
    isduplicate = cellfun(@isDuplicatePadding, varargin, 'UniformOutput', false);
    select = reduce(@and, isduplicate);
    faces(select) = nan;
end

% NB: Transpose only *after* indices have been assigned
faces = faces' ;

% Vertices coordinates: One vertex list per column
varargin = cellfun(@(x) x(:), varargin, 'UniformOutput', false);
vertices = [varargin{:}];

varargout = cell(1, max(1, nargout));
[varargout{:}] = fv(faces, vertices);

end
