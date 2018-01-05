function out = vertcat(fun, numout, varargin)
%VERTCAT Horizontal concatenation of output arguments.
%   X = VERTCAT(FUN,N,A,B,C,...) is equivalent to
%     [X(1,:),X(2,:),...,X(N,:)] = FUN(A,B,C,...).
%
%   Note to maintainers:
%   The interface of this routine is consistent with that of
%   PARFEVAL in the Parallel Computing Toolbox.
%
%   See also VERTCAT, VERTCAT, CAT.

% Equivalently: "compose(@vertcat, fun, numout, varargin{:})"
[temp{1 : numout}] = feval(fun, varargin{:});
out = vertcat(temp{:});
