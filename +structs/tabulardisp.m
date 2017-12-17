function tabulardisp(t, rows)
%TABULARDISP Display tabular struct.
% TABULARDISP(T) displays the tabular struct T without printing
% its name or additional information, such as the size.
% See also DISP, STRUCT2TABLE
narginchk(1, 2)
assert(isstruct(t))
if nargin < 2
    rows = ':';
end
% if ~isscalar(t)
%     % Try to accommodate an array of structs
%     t = tabularvertcat(t(rows), false);
%     rows = ':';
% end
disp( ...
    struct2table( ... % adopt built-in tabular format
    tabularnormalize( ... % expand singleton columns
    tabularnomethods( ... % drop singleton functions
    tabularrows(t, rows))))) % select rows
