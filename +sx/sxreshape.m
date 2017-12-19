function a = sxreshape(a, varargin)
%SXRESHAPE Reshape for Singleton eXpansion.
%   See also SXSHAPE.
a = reshape(a, sxshape(a, varargin{:}));
