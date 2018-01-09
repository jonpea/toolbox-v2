function result = reduce(op, result, varargin)
%REDUCE Multi-argument reduction
% REDUCE(OP,A,B,C,...) returns OP( ... OP(OP(OP(A,B),C), ... ).
%
% Examples:
%  REDUCE(OP,A) simply returns A
%  REDUCE(OP,A,B) returns OP(A,B)
%  REDUCE(OP,A,B,C) returns OP(OP(A,B),C)
%  REDUCE(OP,A,B,C,D) returns OP(OP(OP(A,B),C),D)
%  REDUCE(OP,{A,B,C}) works in the same way.
%  REDUCE(@plus,A,B,C) returns A + B + C
%  REDUCE(@minus,A,B,C) returns A - B - C
%  REDUCE(@strcat, 'foo', 'bar', '!') returns 'foobar!'
%
% See also CUMREDUCE.

narginchk(2, nargin)
assert(isa(op, 'function_handle'))

if iscell(result) && isempty(varargin)
    % Accommodate a single cell array
    assert(nargin == 2)
    result = datatypes.reduce(op, result{:}); % recursive call
    return
end

cellfun(@consume, varargin);
    function consume(next)
        result = op(result, next);
    end

end
