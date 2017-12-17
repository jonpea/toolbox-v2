function result = tabularhorzcat(varargin)
%TABULARHORZCAT Horizontal concatenation of tabular structs.
% T = TABULARHORZCAT(T1, T2, ...) concatenates the columns of the 
% tabular structs T1, T2, ... to form a single tabular struct T.
% For this operation to be meaningful, correspnding rows of the 
% arguments must relate to the same subject/entity.
%
% Example:
% >> t1 = struct('Name', {{'Jack'; 'Jim'; 'Julie'}}, 'Age', [34; 25; 16]);
% >> t2 = struct('Height', [1.75; 1.81; 1.79]);
% >> tabulardisp(tabularhorzcat(t1, t2))
%      Name      Age    Height
%     _______    ___    ______
%     'Jack'     34     1.75  
%     'Jim'      25     1.81  
%     'Julie'    16     1.79  
% 
% See also TABULARVERTCAT, HORZCAT, STRUCT2TABLE, TABLE2STRUCT.

assert(all(cellfun(@istabular, varargin)))
assert(isscalar(unique(cellfun(@tabularsize, varargin))))

names = extract(@fieldnames, varargin);
assert(isequal(sort(names), unique(names)))

values = extract(@struct2cell, varargin);

result = cell2struct(values, names, 1);

function result = extract(fun, celloftables)
temp = cellfun(fun, celloftables, 'UniformOutput', false);
result = vertcat(temp{:});
