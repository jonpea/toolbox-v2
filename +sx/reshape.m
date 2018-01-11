function a = reshape(a, varargin)
%RESHAPE Reshape for singleton expansion.
%   See also SX.SHAPE, RESHAPE
a = builtin('reshape', a, sx.shape(a, varargin{:}));
