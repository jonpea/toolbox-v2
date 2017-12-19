function result = tabulartomatrix(tabular, varargin)
%TABULARTOMATRIX Extract fields/columns of a tabular struct as a matrix.
% M = TABULARTOMATRIX(T,'A', 'B', 'C', ...) for tabular struct T returns
% matrix M such that 
%      M(:,1) == T.A,
%       M(:,2) == T.B,
%    and M(:,3) == T.C etc.
% Names that do not correspond to fields of T are ignored.
% See also TABULARROWS, TABULARCOLUMNS.
narginchk(1, nargin)
temporary = struct2cell(tabularcolumns(tabular, varargin));
result = [temporary{:}];
