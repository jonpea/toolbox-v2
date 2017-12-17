function varargout = structsfun(fun, structs, varargin)
%STRUCTSFUN Apply a function to each field of a structure array.
% [A, B, C, ...] = STRUCTSFUN(@(X1, X2), [S1, S2], ...)
% generalizes STRUCTFUN from scalar structs to struct arrays.
% See also STRUCTFUN.
narginchk(2, nargin)
fields = struct2cell(structs);
fields = num2cell(fields, (1 : ndims(structs)) + 1);
fields = cellfun(@squeezefirst, fields, 'UniformOutput', false);
aggregate = cell2struct(fields, fieldnames(structs), 1);
nout = max(nargout(fun), nargout); % invocation from the command prompt
[varargout{1 : nout}] = structfun(@(args) fun(args{:}), aggregate, varargin{:});

function a = squeezefirst(a)
%SQUEEZEFIRST Squeezes the first dimension from a (1xNx...) array.
shape = size(a);
assert(shape(1) == 1)
% A size vector must have at least two elements: 
% Here, the trailing 1 has no impact on the actual shape.
a = reshape(a, [shape(2 : end), 1]); 
