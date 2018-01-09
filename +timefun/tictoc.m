function cleaner = autotimer(label)
narginchk(1, 1)
assert(ischar(label))
starttime = tic;
cleaner = onCleanup(@() ...
    fprintf('%s: Elapsed time is %g seconds\n', label, toc(starttime)));
end
