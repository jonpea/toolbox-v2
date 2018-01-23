function [tnear, tfar] = raylimits(classname)
narginchk(1, 1)
delta = 0.0; %1e-3;
tnear = cast(delta, classname);
tfar = cast(1 - delta, classname);
