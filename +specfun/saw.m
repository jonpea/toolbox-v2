function y = saw(t, a)
%SAW Sawtooth waveform.
%   SAW(X) is a sawtooth function of the elements of X with period 2.
%
%   SAW(X,L) is the L-periodic sawtooth function of the elements of X.
%   The period L may be scalar or the same size as X.
%
%   Properties of SAW(_,L):
%   - L-periodic
%   - odd (anti-symmetric)
%   - range is [-1,1]
%   - linear over [-L/2,L/2]
%   - discontinuous at integer multiples of L/2
%
%   For further information, see
%   https://en.wikipedia.org/wiki/Sawtooth_wave.
%
%   See also TRI.

narginchk(1, 2)

if nargin < 2
    a = 2;
end

x = t./a;
%y = period.*(x - floor(x));
y = 2*(x - floor(0.5 + x));
