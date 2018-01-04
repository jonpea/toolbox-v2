function embreemexbuild(varargin)

files = varargin;
[mexflags, files] = getflags('-', files{:});
[compflags, files] = getflags('/', files{:});
if isempty(files)
    files = cellstr(ls(fullfile('embree', '*.cpp')));
end
buildwithflags = @(cppfile) build(cppfile, mexflags, compflags);
cellfun(buildwithflags, files);

end

% -------------------------------------------------------------------------
function build(cppfile, mexflags, compflags)
% For further details on Windows build flags, see
% https://msdn.microsoft.com/en-us/library/2kzt1wy3(v=vs.140).aspx

fprintf('===== Building %s =====\n', cppfile)

% usetbb = false;
% 
% if usetbb
%     libfolder = 'embree-cmake-build-tbb';
% else
%     libfolder = 'embree-cmake-build';
% end

mexincdir = fullfile(pwd, 'mexfiles');

assert(strcmpi(computer('arch'), 'win64'), ...
    'Embree is not yet configured for %s', computer)
embreebasedir = fullfile(pwd, 'embree', 'embree-2.16.5.x64.windows');
embreeincdir = fullfile(embreebasedir, 'include');
embreelibdir = fullfile(embreebasedir, 'Release');
embreelibs = cellfun( ...
    @(libname) quote(fullfile(embreelibdir, libname)), ...
    {
    'embree.lib' ...
    'embree_avx.lib' ...
    'embree_avx2.lib' ...
    'embree_sse42.lib' ...
    'lexers.lib' ...
    'simd.lib' ...
    'sys.lib'  ...
    'tasking.lib'
    ... 'scenegraph.lib' ... % apparently unnecessary
    }, ...
    'UniformOutput', false);
embreemacros = { '-D_WIN32', '-DEMBREE_STATIC_LIB' };

% if usetbb
%     if true
%         % Intel's own distribution
%         tbbdir = @(part) ...
%             fullfile(embreebasedir, 'tbb2018_20170726oss', part, 'intel64', 'vc14');
%         tbblibdir = tbbdir('lib');
%         tbbdlldir = tbbdir('bin');
%     else
%         % MATLAB's distribution does not include .lib files
%         tbbdlldir = fullfile('C:', 'Matlab', 'R2017a', 'Pro', 'bin', 'win64');
%         tbblibdir = tbbdlldir;
%     end
%     
%     tbblibs = {
%         mexflag('L', tbblibdir) ...
%         mexflag('L', tbbdlldir) ...
%         '-ltbb' ...
%         '-ltbbmalloc' ...
%         }; %#ok<NASGU>
%     
%     embreelibs = [embreelibs, tbblibs];  %#ok<UNRCH>
% end

compilersettings = join(['/W4 /MT /Ox', compflags]);
assert(isscalar(compilersettings))
compilersettings = compilersettings{1};

mexcommand = {
    mexflags{:} ... % e.g. '-g' for mxAssert, '-v' for verbose output
    embreemacros{:} ...
    sprintf('COMPFLAGS="$COMPFLAGS %s"', compilersettings), ... % override '/MD' with '/MT'"
    mexflag('I', mexincdir) ...
    mexflag('I', embreeincdir) ...
    '-outdir', relativepath('embree') ...
    relativepath('embree', cppfile) ...
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

% -------------------------------------------------------------------------
function s = relativepath(varargin)
s = fullfile('.', varargin{:});
end
