function varargout = compose(fouter, finner, numout, varargin)
%COMPOSE Function composition.
%   [...] = COMPOSE(OUTER,INNER,N,A,B,C,...) is equivalent to
%     [T1,T2,...,TN] = INNER(A,B,C,...);
%     [...] = OUTER(T1,T2,...,TN).
%
%   Note to maintainers:
%   The interface of this routine is consistent with that of
%   PARFEVAL in the Parallel Computing Toolbox.
%
%   See also VERTCAT, VERTCAT, CAT.

nout = arguments.nargoutfor(fouter, nargout);
[temporary{1 : numout}] = feval(finner, varargin{:});
[varargout{1 : nout}] = feval(fouter, temporary{:});
