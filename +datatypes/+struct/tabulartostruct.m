function s = tabulartostruct(t)
%TABULARTOSTRUCT Convert tabular struct to arrays of structs
% Example:
% >> t = struct('Name', {{'Albert'; 'Barbara'}}, 'Age', [18; 35]);
% >> s = tabulartostruct(t)
% >> arrayfun(@disp, s)
%     Name: 'Albert'
%      Age: 18
% 
%     Name: 'Barbara'
%      Age: 35
%
% See also TABULARTOMATRIX.

values = cellfun(@rowstocells, struct2cell(t), 'UniformOutput', false);
names = fieldnames(t);
temporary = [names(:), values(:)]';
s = struct(temporary{:});

function a = rowstocells(a) 
if size(a, 1) == 1 || iscell(a)
    return % singletons and cellstr's are handled by STRUCT()
end
exceptrows = 2 : ndims(a);
a = num2cell(a, exceptrows);
