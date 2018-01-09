function varargout = dealcell(varargout)
%DEALOUT Deal cell array of inputs to individual outputs.
%   [A,B,C,..] = DEALOUT({X,Y,Z,..}) simply assigns elements of 
%   the cell array to the corresponding output arguments. 
%
%   Example:
%   >> [a, b] = dealout(num2cell(setdiff(1 : 3, 2)))
%   a =
%        1
%   b =
%        3
%
% See also DEAL, VARARGOUT.
