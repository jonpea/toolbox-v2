function initialize

fprintf('<strong>Environment</strong>\n')
parallel.numcores

fprintf('\nRun <strong>compile</strong> to build mex functions\n')

fprintf('\nRun <strong>contracts.ndebug</strong> to enable <strong>assert</strong>\n')

fprintf('\nRun <strong>format debug</strong> to display mex pointers\n')

dbstop if error
dbstop if warning

%format short g
%format debug

