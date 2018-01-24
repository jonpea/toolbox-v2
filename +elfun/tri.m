function y = tri(t)
%TRI Triangle waveform.
%   TRI(X) is the triangle function of the elements of X with unit
%   half-period and unit amplitude.
%
%   A.*TRI(X./L) is the triangle function of the elements of X 
%   with half-period L and amplitude A. 
%
%   Properties of A.*TRI(X./L):
%   - (2*L)-periodic
%   - even (symmetric)
%   - range is [-A,A]
%   - linear over [0,L]
%
%   For further information, see
%   https://en.wikipedia.org/wiki/Triangle_wave.
%
%   See also SAW.

y = abs(elfun.saw(t));
