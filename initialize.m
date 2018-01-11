function initialize

fprintf('<strong>Kakapo Geometrical Optics Toolbox</strong> (version 0.1)\n')
fprintf('Dept of Electrical & Computer Engineering\n')
fprintf('The University of Auckland\n')
fprintf('\n')

fprintf('<strong>Environment</strong>\n')
parallel.numcores

fprintf('\n<strong>Mex-files</strong>\n')
fprintf('Run <strong>compile</strong> to build mex functions\n')
fprintf('Run <strong>format debug</strong> to display mex pointers\n')

fprintf('\n<strong>Assertions</strong>\n')
contracts.ndebug(true) % disables all assert statements
fprintf('Run <strong>contracts.ndebug(false)</strong> to enable <strong>assert</strong>\n')
dbstop if error
dbstop if warning

%format short g
%format debug

fprintf('\n<strong>Path</strong>\n')
bfo = fullfile('.', 'bfo_and_examples_v1.01');
fprintf('Added <strong>bfo</strong> to path: %s\n', bfo)
addpath(bfo)
