function tabular = tabularcolumns(tabular, varargin)
%TABULARCOLUMNS Extract columns of a tabular struct.
% TABULARCOLUMNS(T,'A','B','C',...) for tabular struct T returns fields
% T.A, T.B, T.C, ... etc. in another tabular struct.
% TABULARCOLUMNS(T,{'A','B','C',...}) works in the same way.
% Field names that do not actually belong to T are ignored.
% See also TABULARROWS.
narginchk(1, nargin)
if numel(varargin) == 1 && iscell(varargin{1})
    varargin = varargin{1};
end
assert(iscellstr(varargin))
assert(all(ismember(varargin, fieldnames(tabular))))
tabular = rmfield(tabular, ...
    setdiff(fieldnames(tabular), varargin));
tabular = orderfields(tabular, varargin);
