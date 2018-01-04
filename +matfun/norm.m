function norms = norm(a, p, varargin)
%NORM Vector norm over array slices.
%   NORM(A,P,DIM) is the P-norm of each slice through the dimension DIM of
%   array A.
%
%   NORM(A,P) operates along the first non-singleton dimension of A.
%
%   NORM(A) returns the 2-norm along the first non-singleton dimension.
%
%   Examples:
%   >> a = ones(2, 3);
%   >> sx.norm(a)
%   ans =
%          1.4142       1.4142       1.4142
%
%   >> sx.norm(a, 1)
%   ans =
%          1.4142       1.4142       1.4142
%
%   >> sx.norm(a, 2)
%   ans =
%          1.7321
%          1.7321
%
%  See also NORM.

import contracts.ndebug

narginchk(1, 3)

if nargin < 2 || isempty(p)
    p = 2;
end

assert(ndebug || isscalar(p) && isnumeric(p))

if isinf(p)
    
    if isempty(a)
        %
        % Special cases 1.1: The norm of an empty vector is (correctly)
        % zero, whereas min/max applied to an empty array is empty.
        %
        shape = size(a);
        dim = sx.leaddim(a, varargin{:});
        
        % NB: Do *not* add trailing zeros; MATLAB drops trailing
        % ones (in dimensions >2) but retains all zero dimensions
        shape(end + 1 : dim) = 1;
        
        shape(dim) = 1;
        norms = zeros(shape, 'like', a);
    else
        %
        % Special cases 1.2: min/max norm
        %
        if p < 0
            reduce = @min;
        else
            reduce = @max;
        end
        norms = reduce(abs(a), [], varargin{:});
    end
    
    return
    
end

assert(ndebug || 1 <= p)

% Remaining cases: p-norm with finite p
switch mod(p, 2)
    case 0 % even power
        magnitude = @(x) x;
    case 1 % odd power
        magnitude = abs(a);
end

% NB: SUM operates along the first non-singleton dimension by default
norms = power(sum(magnitude(a).^p, varargin{:}), 1/p);
