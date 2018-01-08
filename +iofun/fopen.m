function [fid, cleaner] = fopen(filename, varargin)

if nargin == 1 && isnumeric(filename) && isscalar(filename)
    % Caller has already obtained a file identifier
    fid = filename;
    cleaner = [];
    return
end

assert(ischar(filename))

fid = fopen(filename, varargin{:});

% If fopen cannot open the file, then file identifier is -1.
if fid < 0
    warning( ...
        contracts.msgid(mfilename, 'CannotOpenFile'), ...
        'Error opening file %s.', filename)
end

if ismember(fid, 0 : 2)
    % MATLAB reserves file identifiers
    % 0 for standard input,
    % 1 for standard output (the screen), and
    % 2 for standard error, respectively.
    % Hence, these files should not be closed.
    cleaner = [];
else
    cleaner = onCleanup(@() fclose(fid));
end
