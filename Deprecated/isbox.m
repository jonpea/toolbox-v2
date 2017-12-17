function tf = isbox(varargin)

import facevertex.fv
import graphics.bbox

[faces, vertices] = facevertex.fv(varargin{:});

extremes = bbox(vertices);

switch size(vertices, 2)
    case 2
        
    case 3
end

[lowerfound, lowerfacevertices] = ismember(lowervertices, model.Vertices, 'rows');
[upperfound, upperfacevertices] = ismember(uppervertices, model.Vertices, 'rows');

assert(~axisaligned || (all(lowerfound) && all(upperfound)), ...
    'Plan does not appear to be axis-aligned and rectangular.')

if floor
    newlowervertexids = size(model.Vertices, 1) + (1 : sum(~lowerfound));
    lowerfacevertices(~lowerfound) = newlowervertexids;
    model.Faces(end + 1, :) = lowerfacevertices(:)';
    model.Vertices(newlowervertexids, :) = lowervertices(~lowerfound, :);
end

if ceiling
    newuppervertexids = size(model.Vertices, 1) + (1 : sum(~upperfound));
    upperfacevertices(~upperfound) = newuppervertexids;
    model.Faces(end + 1, :) = upperfacevertices(:)';
    model.Vertices(newuppervertexids, :) = uppervertices(~upperfound, :);
end

varargout = cell(1, max(1, nargout));
[varargout{:}] = facevertex.fv(model);
