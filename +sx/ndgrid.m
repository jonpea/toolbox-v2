function varargout = ndgrid(varargin)
%NDGRID Rectangular grid vectors in N-D space.
%
%   Example:
%   >> [x, y, z] = sx.ndgrid([1 2 3], [4 5], [6 7 8])
%   x =
%        1
%        2
%        3
%   y =
%        4     5
%   z(:,:,1) =
%        6
%   z(:,:,2) =
%        7
%   z(:,:,3) =
%        8
%
%   See also SX.MESHGRID, NDGRID, MESHGRID.

narginchk(1, nargin)

if nargin == 1 
    % Support for square/homogeneous grid 
    % e.g. "[x,y,z] = ndgrid(1:10)"
    varargin = repmat(varargin, 1, max(1, nargout));
end

numaxes = numel(varargin);
assert(nargout <= numaxes)

shape = ones(1, numaxes); % (1) generate once, ...
    function x = orientVector(dim, numel)
        x = varargin{dim};
        if ~isvector(x)
            % Accommodates mixture of grid vectors and expanded arrays [**]
            return
        end
        shape(dim) = numel; % (2) ... insert, ...
        x = reshape(varargin{dim}, shape);
        shape(dim) = 1; % (3) ... and reset.
    end

varargout = arrayfun(@orientVector, ...
    1 : numaxes, ...
    cellfun(@numel, varargin), ...
    'UniformOutput', false);

% [**] If original arguments were not all vectors, check compatibility
if ~sx.iscompatible(varargout{:})
    warning(arguments.msgid(mfilename, 'SXIncompatible'), ...
        'The given list is incompatible with singleton expansion.')
end

end
