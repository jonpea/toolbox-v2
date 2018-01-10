function [origin, normal, tangents, map] = frames(faces, vertices)
%FVFRAMES Local coordinate frames for face-vertex representation
% [FRAME,NORMAL,OFFSET,ORIGIN,MAP]=FRAMES(FACES,TANGENTS{:}) returns frame
% data for face-vertex models in the rows of the following arrays:
%
%  FRAME(K,:,:) - Complete set of frame vectors for facet K
%
%    MAP(K,:,:) - coefficients of the offset-to-local-coordinates map
%                   that is evaluated as
%                     SQUEEZE(SUM(MAP(K,:,:).*(X-ORIGIN(K,:)), 2))
%
%   NORMAL(K,:) - unit normal vector for facet K
%
%     OFFSET(K) - offset term in implicit representation
%                   DOT(NORMAL(K,:),X) == OFFSET(K)
%                 of all points X in facet K
%

narginchk(2, 2)
assert(ismatrix(faces))
assert(ismatrix(vertices))
assert(ismember(size(vertices, 2), 2 : 3))
assert(ismember(size(faces, 2), 2 : 4))

numfaces = size(faces, 1);
classtype = class(vertices);
    function result = allocate(varargin)
        result = zeros(numfaces, varargin{:}, classtype);
    end

% Pre-allocate to ensure results are properly
% dimensioned even when first argument is empty
numdimensions = size(vertices, 2);
origin = allocate(numdimensions);
normal = allocate(numdimensions);
[tangents, map] = deal(allocate(numdimensions, numdimensions - 1));
[origin(:, :), normal(:, :), tangents(:, :, :), map(:, :, :)] = ...
    combineIndividualFrames(faces, vertices);

end

function varargout = combineIndividualFrames(faces, vertices)
[varargout{1 : nargout}] = cellfun( ...
    @(face) reference.frame(face, vertices), ...
    num2cell(faces, 2), ...
    'UniformOutput', false);
varargout = cellfun(@cell2mat, varargout, 'UniformOutput', false);
end
