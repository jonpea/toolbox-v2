function [start, step, stop] = colonparts(varargin)
%COLONPARTS Parse elements of colon operator.
%   [START,STEP,STOP] = COLONPARTS(C) correspond to
%   colon generator START:STEP:STOP of 1:1:C.
%
%   [START,STEP,STOP] = COLONPARTS(A,C) correspond to
%   colon generator START:STEP:STOP of A:1:C.
%
%   [START,STEP,STOP] = COLONPARTS(A,B,C) correspond to
%   colon generator START:STEP:STOP of A:B:C.
%
%   See also COLON.
narginchk(1, 3)
switch nargin
    case 1
        stop = varargin{:};
        start = ones('like', stop);
        step = ones('like', stop);
    case 2
        [start, stop] = varargin{:};
        step = ones('like', stop);
    case 3
        [start, step, stop] = varargin{:};
end
assert(isscalar(start))
assert(isscalar(stop))
assert(isscalar(step) && step ~= 0)
end