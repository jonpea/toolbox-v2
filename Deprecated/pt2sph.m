function [az, inc, r] = pt2sph(az, elev, r)
%SPHTOGGLE Toggle between azimuth-elevation and azimuth-inclination form.

% Involutive transformation between elevation and inclination
inc = pi/2 - elev;
