function varargout = dealin(fun, first, varargin)
%DEALIN Deals input arguments to a function.
%   [X,Y,..] = DEALIN(FUN,{A,B,..},U,V,..) with function handle FUN is
%   equivalent to [X,Y,..] = FUN(A,B,..,U,V,..)
%   i.e. the second argument is dealt to FUN.
%
%   See also ARGUMENTS.UNDEAL, DEAL.

narginchk(2, nargin)
numout = arguments.nargoutfor(fun, nargout);
[varargout{1 : numout}] = fun(first{:}, varargin{:});
