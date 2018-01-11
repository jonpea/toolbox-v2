function varargout = expand(varargin)
%EXPAND Explicit singleton expansion.
%   [AX,BX] = EXPAND(A,B) explicitly expands singleton dimensions 
%   such that elementwise operations may be performed on AX and BX.
%
%   [A1X,A2X,...,ANX] = EXPAND(A1,A2,...,AN) performs explicit singleton
%   expansion for N-ary elementwise operations.
%
%   NB: Since MATLAB performs implicit singleton expansion, this
%   function is intended *only* for the following scenerios:
%   - testing and performance profiling
%   - correctly accounting for the shape of unused arguments
%
%   Example: 
%   The following three functions are mathematically equivalent
%   >> f1 = @(x, y) sin(x + zeros(size(y))  % naive version
%   >> f2 = @(x, y) sin(sx.expand(x, y));   % more efficient
%   >> f3 = @(x, y) sx.expand(sin(x), y);   % most efficient
%
%   In contrast, the following function not equivalent to f1/f2/f3:
%   >> f4 = @(x, ~) sin(x);                 % no singleton expansion
%   >> f5 = @(x, y) sin(sx.expand(y, x));   % like "sin(y)"
%
%   See also SIZESX, BSXFUN.

commonshape = sx.size(varargin{:});
numdims = numel(commonshape);
    function inflated = inflateArray(a)
        [shape{1 : numdims}] = size(a); % excess dimensions have size one
        shape = cell2mat(shape);
        issingleton = shape == 1;
        shape(issingleton) = commonshape(issingleton); % inflate current singletons
        shape(~issingleton) = 1; % preserve current non-singletons
        inflated = repmat(a, shape);
    end

varargout = cellfun( ...
    @inflateArray, ...
    varargin(1 : max(1, nargout)), ... % skips redundant outputs
    'UniformOutput', false);

end
