function time = starttimer(varargin)
%STARTTIMER Start a stopwatch timer with banner.
% See also STOPTIMER, TIC, TOC.
narginchk(1, nargin)
time = [];
if istimerenabled || nargout == 1
    time = tic;
    % if istimerenabled
    %     fprintf(varargin{:})
    % end
end
