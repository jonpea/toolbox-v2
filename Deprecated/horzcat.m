function out = horzcat(fun, numout, varargin)
%HORZCAT Horizontal concatenation of output arguments.
%   X = HORZCAT(FUN,N,A,B,C,...) is equivalent to
%     [X(:,1),X(:,2),...,X(:,N)] = FUN(A,B,C,...).
%
%   Note to maintainers:
%   The interface of this routine is consistent with that of
%   PARFEVAL in the Parallel Computing Toolbox.
%
%   See also HORZCAT, VERTCAT, CAT.

% Equivalently: "compose(@horzcat, fun, numout, varargin{:})"
[temp{1 : numout}] = feval(fun, varargin{:});
out = [temp{:}];