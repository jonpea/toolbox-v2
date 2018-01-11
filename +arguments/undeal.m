function out = undeal(fun, numout, varargin)
%UNDEAL Captures multiple output arguments in a single cell array.
%   OUT = UNDEAL(FUN,N,..) captures all N output arguments 
%   [A1,..,AN] = FUN(..) into a single cell array OUT = {A1,..,AN}.
%
%   Example:
%   >> arguments.undeal(@qr, 2, rand(3))
%   ans =
%     1×2 cell array
%       {3×3 double}    {3×3 double}
% 
%   See also ARGUMENTS.DEAL, DEAL.

narginchk(2, nargin)
[out{1 : numout}] = fun(varargin{:});
