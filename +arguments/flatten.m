function list = flatten(varargin)

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
