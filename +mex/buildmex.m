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

