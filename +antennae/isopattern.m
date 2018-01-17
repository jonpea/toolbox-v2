function fun = isopattern(gain)
%ISOPATTERN Interface for combining multiple isotropic antenna patterns.
%   FUN = ISOPATTERN(C) for numeric array C returns a function handle FUN
%   for which FUN(K,X) returns C(K) where K is an array of indices of scene
%   entities and X is a matrix of global Cartesian directions (which is
%   ignored by FUN). 
%
%   FUN = ISOPATTERN(S) for scalar value S returns a function handle FUN
%   for which F(K,X) returns REPMAT(S,SIZE(K)). 
%
%   FUN = ISOPATTERN(P) for some unary function handle P returns a function
%   handle FUN for which FUN(K,X) returns P(K). 
%
%   ISOPATTERN() is equivalent to ISOPATTERN(0).
%
%   See also MULTIPATTERN.

if nargin < 1 || isempty(gain)
    gain = 0.0;
end

if isnumeric(gain)
    if isscalar(gain)
        gain = @(indices) repmat(gain, size(indices)); % constant result
    else
        gain = gain(:); % ensures FUN will always return column vector
    end
end

    function result = evaluate(indices, ~)
        result = gain(indices(:));
    end
fun = @evaluate;

end
