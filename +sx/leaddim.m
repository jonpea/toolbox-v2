function dim = leaddim(a, dim)
%LEADDIM First non-singleton dimension for unary operations.
%   DIM = LEADDIM(A) returns the index of the first
%   non-singleton dimension of A, or 1 if A is scalar-valued.
%
%   DIM is consistent with the default value of the optional second
%   argument of standard unary functions like DIFF, MEAN, PROD, SUM etc.
%   i.e. ISEQUAL(SUM(A), SUM(A,DIM))
%
%   Note that non-singleton dimensions may have size zero e.g.
%   >> leaddim(ones(0, 1))
%   ans =
%        1
%   >> leaddim(ones(1, 0))
%   ans =
%        2
%
%   This behavious is consistent with built-in functions e.g.
%   >> sum(ones(0, 2))
%   ans =
%        0     0
% 
%   >> sum(ones(2, 0))
%   ans =
%     1×0 empty double row vector
%
%   LEADDIM(A, DIM) simply returns DIM.
%   This provides a convenient interface for callers,
%   e.g.
%   function result = mysum(a, varargin)
%      narginchk(1, 2) % varargin may or may not contain "dim"
%      dim = leadingdimension(a, varargin{:})
%      result = sum(a, dim); % built-in function
%   end
%
%   See also NDIMS, SIZE.

narginchk(1, 2)

if nargin == 2
    % Always accept "manual over-ride" via second argument
    return
end

if isscalar(a)
    % Special case is less expensive than the calls below.
    % Note that MATLAB drops trailing unit dimensions so 
    % arrays of size [1 ... 1] have at most two dimensions.
    dim = 1;
    return
end

dim = find(size(a) ~= 1, 1, 'first');
