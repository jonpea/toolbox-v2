function tf = isfull(varargin)
%ISFULL True for points in full grid format.

numdirections = numel(varargin);

% NB: "<=" is employed (as opposed to "==") 
% because NDIMS() ignores trailing singleton dimensions.
tf = iscell(varargin) && ...
    contracts.issame(@size, varargin{:}) && ... 
    all(cellfun(@isnumeric, varargin)) && ... 
    all(cellfun(@(a) ndims(a) <= numdirections, varargin));
