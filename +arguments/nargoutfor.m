function nout = nargoutfor(fun, nout)
%NARGOUTFOR Number of output arguments without explicit assignment.
%   N = NARGOUTFOR(FUN,NARGOUT) returns the number of output arguments 
%   that should be used in a client function, CALLER, when the outputs of
%   FUN under may be received at the command prompt:
%
%   function varargout = CALLER(FUN, ...)
%   ...
%   CALLERNARGOUT = nargout; % nargout in the context of CALLER
%   N = nargoutfor(FUN, CALLERNARGOUT); 
%   [varargout{1 : N}] = FUN(...);
%
%   Scenarios
%   1. CALLER is invoked from the command prompt without explicit 
%      assignment of the output at the point of invocation:
%      1a. NARGOUT(FUN) == 0: Then N == 0
%      1b. NARGOUT(FUN) ~= 0: Then N == 1
%
%   2. CALLER is invoked with explicit assignment of the output(s) at the
%        point of invocation: Then N == CALLERNARGOUT.
%
%   NB: In Scenario 2, the client of CALLER dictates the number of outputs
%   and the client is therefore responsible for ensuring that this number
%   does not exceed the maximum number of outputs returned by |fun|.
%
%   See also NARGOUT, VARARGOUT, VARARGIN.

narginchk(2, 2)
assert(isfunction(fun))
assert(isscalar(nout) && 0 <= nout, ...
    'Second argument should be value of NARGOUT in caller''s context.')

% Number of outputs if invoked interactively with no explicit assignment.
zeroOrOne = min(max(nargout(fun), 0), 1);
%
% NB: Unfortunately, nargout() doesn't fully analyze it's argument, so 
%     we *cannot* conclude
%        "nargout(fun) == -1" => "fun returns at least one argument".
%
% Example:
% >> nargout(@disp)
% ans =
%      0
% >> nargout(@(x) disp(x))
% ans =
%     -1
%
% This is the reason that "min(abs(nargout(fun)), 1)" is not used.
%

% Number of outputs if invoked with explicit assignment
zeroOrMore = nout;

nout = max(zeroOrOne, zeroOrMore);
