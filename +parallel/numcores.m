function varargout = numcores
%NUMCORES Number of processor cores available to MATLAB.
%   NUMCORES displays the number of physical and logical processor cores
%   available to MATLAB.
%
%   N = NUMCORES returns the number of physical cores available to MATLAB.
%
%   Warning:
%   This function relies on an undocumented function that
%   may be removed in a future version of MATLAB (currently R2017a).
%
%   See also maxNumCompThreads.

switch nargout
    case 0
        feature('numcores');
    case 1
        varargout{1} = feature('numcores');
end
