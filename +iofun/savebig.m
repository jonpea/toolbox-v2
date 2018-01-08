function savebig(varargin)
%SAVEBIG Save workspace variables to file.
% SAVEBIG delegates to SAVE but specifies the new format 
% that supports variables that may be larger than 2GB in size.
% See also SAVE.
narginchk(1, nargin) % must provide, at least, the file name
assert(all(cellfun(@ischar, varargin)))
argumentstring = join(varargin, ' ');
if iscell(argumentstring)
    % It seems that join() in R2017a does not conform to the interface
    % adopted for this function in earlier versions of MATLAB.
    assert(isscalar(argumentstring))
    argumentstring = argumentstring{:};
end
evalin('caller', sprintf('save %s -v7.3', argumentstring))
