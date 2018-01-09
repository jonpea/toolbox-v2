function varargout = stoptimer(started)
%STOPTIMER Stop a stopwatch timer.
% See also STARTTIMER, TIC, TOC.
narginchk(1, 1)
nargoutchk(0, 1)
if istimerenabled || nargout == 1
    assert(isscalar(started))
    elapsed = toc(started);
    % if istimerenabled
    %     fprintf(' %g sec\n', elapsed)
    % end
    if nargout == 1
        varargout{1} = elapsed;
    end
end
