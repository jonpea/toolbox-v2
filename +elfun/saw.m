function y = saw(t)
%SAW Sawtooth waveform.
%   SAW(X) is the sawtooth function of the elements of X with unit
%   half-period and unit amplitude. 
%
%   A.*SAW(X./L) is the sawtooth function of the elements of X with 
%   half-period L and amplitude A. 
%
%   Properties of A.*SAW(X./L):
%   - odd (anti-symmetric)
%   - (2*L)-periodic
%   - range is [-A,A]
%   - linear over [-L,L]
%
%   For further information, see
%   https://en.wikipedia.org/wiki/Sawtooth_wave.
%
%   See also TRI.

narginchk(1, 1)

halfperiod = 1;
amplitude = 1;

period = 2*halfperiod;
x = t./period;
y = 2*amplitude*(x - floor(0.5 + x));
