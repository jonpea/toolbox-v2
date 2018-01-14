function varargout = catfaces(varargin)
%CATFACES Concatenate face arrays from multiple face-vertex models.
%   F = FACEVERTEX.CATFACES(F1,F2,...,FN) with face arrays F1,F2,...FN 
%   of N face-vertex polygon complexes returns a new a new face array F 
%   formed by contatenating F1,...,FN.
%
%   FACEVERTEX.CATFACES(..,'nan') pads trailing columns with NaN if the
%   face arrays have heterogeneous sizes.
%
%   FACEVERTEX.CATFACES(..,'duplicate') pads trailing columns with
%   duplicates of the final value in each row if face arrays have
%   heterogeneous sizes. 
%
%   Use FACEVERTEX.COMPRESS to reindex connectivity to eliminate possible
%   duplication between the vertices of C1,C2,...,CN.
%
%   See also FACEVERTEX.COMPRESS, CAT, VERTCAT, PATCH.

import facevertex.fv

% Parse optional argument
if ischar(varargin{end})
    padding = varargin{end};
    varargin(end) = [];
else
    padding = 'nan'; % default
end

% Pass primary arguments
if all(cellfun(@isstruct, varargin))
    assert(mod(numel(varargin), 2) == 0)
    [varargin, ~] = cellfun(@fv, varargin, 'UniformOutput', false);
end

% Preconditions
assert(ischar(padding))
assert(all(cellfun(@(f) ismatrix(f) && isnumeric(f), varargin)))

% Pad columns of connectivity lists to ensure conformity
switch validatestring(padding, {'nan', 'duplicate'})
    case 'nan'
        padder = @padNaN;
    case 'duplicate'
        padder = @padDuplicate;
end
maxNumColumns = max(cellfun(@(s) size(s.Faces, 2), varargin));
varargin = cellfun( ...
    @(s) padder(s, maxNumColumns), varargin, ...
    'UniformOutput', false);

% Concatenate successive pairs
c = datatypes.reduce(@catPair, varargin);

varargout = cell(1, max(1, nargout));
[varargout{:}] = fv(c);

end

% -------------------------------------------------------------------------
function c = catPair(a, b)
%CATPAIR Concatenate a single pair of polygon complexes.

import datatypes.struct.structsfun

% Vertical concatenation of *all* fields i.e. including any 
% user-specified fields, in addition to 'Faces', and 'Vertices'. 
c = structsfun(@vertcat, a, b, 'UniformOutput', false);

% Indices into rows of Vertices must be offset appropriately
c.Faces = [
    a.Faces;
    b.Faces + size(a.Vertices, 1);
    ];

end

% -------------------------------------------------------------------------
function s = padNaN(s, n)
%PADNAN Pad columns of a connectivity array with NaNs.
%  See also PATCH.
s.Faces(:, end + 1 : n) = nan;
end

% -------------------------------------------------------------------------
function s = padDuplicate(s, n)
%PADDUPLICATE Pads columns of a connectivity array with duplicates.
%   See also PATCH.
m = n - size(s.Faces, 2);
s.Faces(:, end + 1 : n) = repmat(s.Faces(:, end), 1, m);
end
