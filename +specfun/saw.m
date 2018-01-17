function y = saw(x, period)
%SAW Sawtooth function.
%   SAW(X) is the 1-periodic sawtooth function of the elements of X.
%
%   SAW(X,L) is the L-periodic sawtooth function of the elements of X. 
%   The period L may be scalar or the same size as X.
%
%   See also SIN.

narginchk(1, 2)

if nargin < 1
    period = cast(2*pi, class(x));
end

t = x./period;
y = period.*(t - floor(t));
