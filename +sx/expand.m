function varargout = expand(varargin)
%EXPAND Explicit singleton expansion.
%   [AX,BX] = EXPAND(A,B) explicitly expands singleton dimensions 
%   such that elementwise operations may be performed on AX and BX.
%
%   [A1X,A2X,...,ANX] = EXPAND(A1,A2,...,AN) performs explicit singleton
%   expansion for N-ary elementwise operations.
%
%   NB: Since MATLAB performs implicit singleton expansion, this
%   function is intended *only* for testing and performance profiling.
%
%   See also SIZESX, BSXFUN.

import singletonexpansion.sizesx

commonshape = sizesx(varargin{:});
numdims = numel(commonshape);
    function inflated = inflateArray(a)
        function shape = inflateSize(a)
            shape = size(a);
            shape(end + 1 : numdims) = 1; % pad trailing dimensions
        end
        shape = inflateSize(a);
        checkcompatibility(shape, commonshape)
        issingleton = shape == 1;
        shape(issingleton) = commonshape(issingleton); % inflate current singletons
        shape(~issingleton) = 1; % preserve current non-singletons
        inflated = repmat(a, shape);
    end
varargout = cellfun(@inflateArray, varargin, 'UniformOutput', false);

end

function checkcompatibility(shape1, shape2)
assert(ndebug || ...
    isSingletonExpansionCompatible(shape1, shape2), ...
    'Shapes are incompatible with singleton expansion')
end

function result = isSingletonExpansionCompatible(shape1, shape2)
result = all(1 == shape1 | shape1 == shape2 | shape2 == 1);
end
