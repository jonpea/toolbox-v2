function varargin = cumreduce(op, varargin)
%CUMREDUCE Multi-argument cumulative reduction
% REDUCE(OP,A,B,C,...) returns OP( ... OP(OP(OP(A,B),C), ... ).
%
% Examples:
%  CUMREDUCE(OP,A) returns {A}
%  CUMREDUCE(OP,A,B) returns {A,OP(A,B)}
%  CUMREDUCE(OP,A,B,C) returns {A, OP(A,B), OP(OP(A,B),C)}
%  CUMREDUCE(OP,{A,B,C}) works in the same way.
%  CUMREDUCE(@plus,A,B,C) returns {A,A+B,A+B+C}
%  CUMREDUCE(@minus,A,B,C) returns {A,A-B,A-B-C}
%
% See also CUMSUM, REDUCE, NUM2CELL.

import helpers.cumreduce % for recursive call

narginchk(2, nargin)
assert(isa(op, 'function_handle'))

if iscell(varargin{1}) && numel(varargin) == 1
    % Accommodate a single cell array
    assert(nargin == 2)
    varargin = cumreduce(op, varargin{1}{:});
    return
end

cellfun(@consume, num2cell(1 : numel(varargin) - 1), varargin(2 : end));
    function consume(i, next)
        varargin{i + 1} = op(varargin{i}, next);
    end

end
