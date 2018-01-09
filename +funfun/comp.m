function fun = comp(varargin)
%COMP Composition of functions.
%   FG = COMP(ARG1,ARG2,..) is a function handle for which
%     [X,Y,..] = FG(A,B,..) is equivalent to 
%     [X,Y,..] = PIPE(ARG1,ARG2,..,A,B).
%
%   See also PIPE.

outer = vararin;
fun = @(varargin) funfun.pipe(outer{:}, varargin{:});
