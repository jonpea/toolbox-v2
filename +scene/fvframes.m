function varargout = fvframes(origin, varargin)
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

narginchk(2, 3)
assert(all(cellfun(@(a) isequal(size(origin), size(a)), varargin)))
assert(numel(varargin) == size(origin, 2) - 1)

[numpoints, numdimensions] = size(origin);
edgeaxis = varargin;

switch numdimensions
    case 2
        [unitaxis{1}, r] = unit(edgeaxis{1}, 2);
        tangential = [unitaxis{1}, zeros(numpoints, 1)];
        polar = repmat([0 0 1], numpoints, 1);
        normal = cross(tangential, polar, 2);
        normal(:, end) = [];
        offsetmap{1} = bsxfun(@rdivide, unitaxis{1}, r);
        %frame = [{normal}, unitaxis]; % "normal along x-axis"
    case 3
        [unitaxis{1 : 2}, r11, r12, r22] = orth2(edgeaxis{:}, 2);
        normal = cross(unitaxis{:}, 2);
        offsetmap{1} = unitaxis{1}./r11 - unitaxis{2}.*(r12./(r11.*r22));
        offsetmap{2} = unitaxis{2}./r22;
        %frame = [unitaxis, {normal}]; % "normal along z-axis"
end

frame = [{normal}, unitaxis]; % "normal along x-axis"

offset = dot(normal, origin, 2);

[varargout{1 : 4}] = deal( ...
    cat(3, frame{:}), ... % complete orthonormal frame
    cat(3, offsetmap{:}), ... % maps in-face offset-from-origin to local coordinates
    normal, ... % unit normal vector
    offset); % scalar offset in implicit representation
