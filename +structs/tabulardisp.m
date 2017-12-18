function tabulardisp(t, rows)
%TABULARDISP Display tabular struct.
% TABULARDISP(T) displays the tabular struct T without printing
% its name or additional information, such as the size.
% See also DISP, STRUCT2TABLE

narginchk(1, 2)

if nargin < 2
    rows = ':';
end

assert(isstruct(t))

disp(struct2table(tabularrows(t, rows)))
