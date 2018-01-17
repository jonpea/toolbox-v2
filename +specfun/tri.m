function y = tri(t, a)
%TRI Triangle waveform.
%   TRI(X) is a triangle function of the elements of X with period 2.
%
%   TRI(X,L) is the L-periodic triangle function of the elements of X.
%   The period L may be scalar or the same size as X.
%
%   Properties of TRI(_,L):
%   - L-periodic
%   - even (symmetric)
%   - range is [-1,1]
%   - linear over [0,L/2]
%
%   For further information, see
%   https://en.wikipedia.org/wiki/Triangle_wave.
%
%   See also TRI.

narginchk(1, 2)

if nargin < 2
    a = 2;
end

y = abs(specfun.saw(t, a));
