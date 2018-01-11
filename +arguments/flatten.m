function list = flatten(varargin)
%FLATTEN Packs its argument list into a single cell array.
%
% Examples:
%   >> arguments.flatten({1,2},3,{4,5,6})
%   ans =
%     1×6 cell array
%       {[1]}    {[2]}    {[3]}    {[4]}    {[5]}    {[6]}
%
%   >> arguments.flatten({1,2},{{3}},{4,5,6})
%   ans =
%     1×6 cell array
%       {[1]}    {[2]}    {1×1 cell}    {[4]}    {[5]}    {[6]}
%

varargin = cellfun(@enbrace, varargin, 'UniformOutput', false);
    function c = enbrace(c)
        if ~iscell(c)
            c = {c};
        end
    end

sizes = cellfun(@numel, varargin);
cumsizes = cumsum(sizes);
start = 1 + [0, cumsizes(1 : end - 1)];
finish = cumsizes;

arguments = varargin; % for use in inner function
list = cell(1, sum(sizes));
    function insert(index, start, finish)
        values = arguments{index};
        [list{start : finish}] = values{:};
    end
arrayfun(@insert, 1 : nargin, start, finish)

end
