function embreemexbuild(varargin)

files = varargin;
[mexflags, files] = getflags('-', files{:});
[compflags, files] = getflags('/', files{:});

if isempty(files)
    files = cellstr(ls(embreepath('*.cpp')));
end

cellfun(@(cppfile) build(cppfile, mexflags, compflags), files);

end

% -------------------------------------------------------------------------
function s = embreepath(varargin)
s = fullfile('.', '+embree', varargin{:});
end

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

end

% -------------------------------------------------------------------------
function [flags, varargin] = getflags(head, varargin)
flagindices = cellfun(@(s) strncmp(s, head, 1), varargin);
flags = varargin(flagindices);
varargin(flagindices) = [];
end
