function cleaner = tictoc(varargin)
%TICTOC  Scoped timer.
%   C = TICTOC(LABEL) starts a stopwatch timer that is stopped
%   as soon as C goes out of scope (or is explicitly deleted).
%
%   C = TICTOC(LABEL,FORMAT) specifies the form of the textual output.
%   The format specifier FORMAT should be compatible with SPRINTF and
%   admit two fields:
%   - elaped time is inserted in field 1
%   - LABEL is inserted in field 2
%
%   TICTOC(FID,..) sends the final message to the text file specified by
%   integer file identifier FID.
%
%   Example: Default format to stdout
%   >> scoped = timefun.tictoc('test'); pause(2); clear scoped
%   test: Elapsed time is 2.00088 seconds
%
%   Example: Custom format to stdout
%   >> scoped = timefun.tictoc('test', '[%2$.2g sec for %1$s]\n'); pause(2); clear scoped
%   [2 sec for test]
%
%   Example: Print to an arbitrary file (stderr in this case)
%   >> scoped = timefun.tictoc(2, 'test'); pause(2); clear scoped
%   test: Elapsed time is 2.00079 seconds
%
% See also TIC, TOC, TIMEFUN, ONCLEANUP.

narginchk(1, 3)

[fid, label, varargin] = arguments.parsefirst( ...
    @isnumeric, iofun.stdout, 1, varargin{:});

if isscalar(varargin)
    format = varargin{:};
else
    format = '%s: Elapsed time is %g seconds\n';
end

assert(ischar(label))
assert(ischar(format))

    function fun = wrapCallback
        % NB: This "double-nested" arangement is required by onCleanup
        % to eliminate the possibility of dangling references.
        startTime = tic;
        function finish
            elapsed = toc(startTime);
            fprintf(fid, format, label, elapsed);
        end
        fun = @finish;
    end

cleaner = onCleanup(wrapCallback);

end
