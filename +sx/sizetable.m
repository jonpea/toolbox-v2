function table = sizetable(varargin)
%SIZETABLE Sizes of arguments stored in table rows.
%   T = SIZETABLE(A1,A2,...,AN), where A1, ..., AN are arrays of 
%   identical size, returns the matrix [SIZE(A1); ...; SIZE(AN)];
%   i.e. T(K,:) contains SIZE(AK).
%   
%   If the arguments differ in dimension, each row of T is padded
%   with trailing ones, as necessary to form a full matrix.
% 
% Example:
% >> sizetable(ones(1, 2, 3, 4), ones(5, 6, 7), ones(8, 9))
% ans =
%      1     2     3     4
%      5     6     7     1
%      8     9     1     1
% 
% See also SIZE.

maxndims = max(cellfun(@ndims, varargin));
    function shape = paddedsize(a)
        [temporary{1 : maxndims}] = size(a); % pads with 1s
        shape = cell2mat(temporary);
    end
sizes = cellfun(@paddedsize, varargin, 'UniformOutput', false);
table = vertcat(sizes{:});

end
