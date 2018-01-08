function compile(varargin)
%COMPILE Compile toolbox MEx files.
%   COMPILE(FLAG1,FLAG2, ..) builds the toolbox with command-line flags
%   FLAG1, FLAG2, ....
%
%   Examples: 
%   >> compile -v % for verbose outputs from mex
%   >> compile -g % to enable mxAssert
%

mexflags = varargin;

fprintf('Building Mex files...\n')

build = @(varargin) buildtoolboxmex(varargin{:}, mexflags{:});
% build('mexfiles', 'intersectmex.cpp')
% build('mexfiles', 'pointermex.cpp')
build('+scenes', 'planarmirrormex.cpp')
build('+scenes', 'planarintersectionmex.cpp')

buildembreemex('embreescenemex.cpp', mexflags{:})

% -------------------------------------------------------------------------
function buildtoolboxmex(path, filename, varargin)

narginchk(1, nargin)

arch = computer('arch');

switch arch
    case 'glnxa64'
        mexsettings = {
            'CXXFLAGS="$CXXFLAGS -std=c++14 -O3 -fopenmp"', ...
            'LDFLAGS="$LDFLAGS -fopenmp"', ...
            strcat('-L', fullfile(matlabroot, 'sys', 'os', arch)) ...
            ... '-lpthread', ...
            ... '-liomp5'
            };
        
    case 'win64'
        mexsettings = {
            'CXXFLAGS="$CXXFLAGS /W4 /MT /Ox /openmp"', ...
            'LDFLAGS="$LDFLAGS /openmp"', ...
            ... strcat('-L', fullfile(matlabroot, 'bin', arch)), ...
            ... '-liomp5md'
            };
        
    otherwise
        error('Settings below are not yet tested on platform %s', arch)
end

fprintf('===== Building %s =====\n', filename)

buildmex( ...
    fullfile(pwd, path), ...
    filename, ...
    mex.mexflag('I', '+mex'), ...
    varargin{:}, ... % use '-g' to support mxAssert
    mexsettings{:})

% -------------------------------------------------------------------------
function buildmex(folder, filename, varargin)
narginchk(2, nargin)
abspath = @(varargin) fullfile(folder, varargin{:});
arguments = {
    '-largeArrayDims', ...
    '-outdir', abspath(), ...
    abspath(filename), ...
    strcat('-I', abspath()), ...
    varargin{:}
    };
fprintf('Building with arguments:\n')
cellfun(@disp, arguments);
mex(arguments{:});

% =========================================================================
function buildembreemex(varargin)

files = varargin;
[mexflags, files] = getflags('-', files{:});
[compflags, files] = getflags('/', files{:});

if isempty(files)
    files = cellstr(ls(embreepath('*.cpp')));
end

cellfun(@(cppfile) build(cppfile, mexflags, compflags), files);

% -------------------------------------------------------------------------
function s = embreepath(varargin)
s = fullfile('.', '+embree', varargin{:});

% -------------------------------------------------------------------------
function build(cppfile, mexflags, compflags)
% For further details on Windows build flags, see
% https://msdn.microsoft.com/en-us/library/2kzt1wy3(v=vs.140).aspx

fprintf('===== Building %s =====\n', cppfile)

mexincdir = fullfile(pwd, '+mex');

assert(strcmpi(computer('arch'), 'win64'), ...
    'Embree is not yet configured for %s', computer)
embreebasedir = embreepath('embree-2.16.5.x64.windows');
embreeincdir = fullfile(embreebasedir, 'include');
embreelibdir = fullfile(embreebasedir, 'Release');
embreelibs = cellfun( ...
    @(libname) mex.quote(fullfile(embreelibdir, libname)), ...
    {
    ... % NB: 'scenegraph.lib' is apparently unnecessary
    'embree.lib' ...
    'embree_avx.lib' ...
    'embree_avx2.lib' ...
    'embree_sse42.lib' ...
    'lexers.lib' ...
    'simd.lib' ...
    'sys.lib'  ...
    'tasking.lib' ...
    }, ...
    'UniformOutput', false);
embreemacros = { '-D_WIN32', '-DEMBREE_STATIC_LIB' };

compilersettings = join(['/W4 /MT /Ox', compflags]);
assert(isscalar(compilersettings))
compilersettings = compilersettings{1};

import mex.mexflag

mexcommand = {
    mexflags{:} ... % e.g. '-g' for mxAssert, '-v' for verbose output
    embreemacros{:} ...
    sprintf('COMPFLAGS="$COMPFLAGS %s"', compilersettings), ... % override '/MD' with '/MT'"
    mexflag('I', mexincdir) ...
    mexflag('I', embreeincdir) ...
    '-outdir', embreepath() ...
    embreepath(cppfile) ...
    mexflag('L', embreelibdir) ...
    embreelibs{:}
    }; %#ok<CCAT>

assert(iscellstr(mexcommand))

disp('mex ')
cellfun(@(s) fprintf('\t%s\n', s), mexcommand)

tic
mex(mexcommand{:})
toc

% -------------------------------------------------------------------------
function [flags, varargin] = getflags(head, varargin)
flagindices = cellfun(@(s) strncmp(s, head, 1), varargin);
flags = varargin(flagindices);
varargin(flagindices) = [];
