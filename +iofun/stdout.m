function fid = stdout
%STDOUT File identifier for standard output.
%   STDOUT is the file identifier for standard output.
%
%   Example: 
%   >> fprintf('hello!\n') % sent to standard output by default
%   hello!
%   >> fprintf(iofun.stdout, 'hello!\n')
%   hello!
%
%   See also STDERR, FPRINTF.

fid = 1;
