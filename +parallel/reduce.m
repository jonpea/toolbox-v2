function y = reduce(fun, x, targetlab)
%REDUCE Global reduction to client.
%   Y = REDUCE(FUN,X) reduces the variant arrays X using FUN,
%   and places the result on the client.
%
%   NB: REDUCE(@plus, X) uses the specialized implementation
%   provided by GPLUS and should be preferred over functionally
%   equivalent alternatives such as REDUCE(@(x, y) plus(x, y), X).
%
%   Example:
%   spmd
%     x = labindex;
%   end
%   assert(isequal(reduce(@sum, x), reduce(x)))
%
%   See also GOP, GPLUS, GCAT.

narginchk(2, 3)

if nargin < 3
    % In the typical case that the pool of workers is
    % homogeneous, the default is as good as any other choice.
    targetlab = 1;
end

if isequal(fun, @plus)
    % Special case: Dedicated underlying implementation
    spmd
        temporary = gplus(x, targetlab);
    end
else
    % General case
    spmd
        temporary = gop(fun, x, targetlab);
    end
end

y = temporary{targetlab};
