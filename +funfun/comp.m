function fun = comp(varargin)
%COMP Composition of functions.
%   FUN = COMP(F1,..,FM) is a function handle for which
%     [Y1,Y2,..] = FUN(X1,..,XN) is equivalent to 
%     [Y1,Y2,..] = PIPE({F1,..,FM},..,X1,..,XN).
%
%   Example:
%   >> f = funfun.comp(@sqrt, @exp);
%   >> x = pi;
%   >> assert(isequal(f(x), sqrt(exp(x))))
%
%   See also PIPE.

outer = varargin;
fun = @(varargin) funfun.pipe(outer, varargin{:});
