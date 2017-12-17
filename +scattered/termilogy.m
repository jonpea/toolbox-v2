% Definitions 
%
% These are provided in the documentation of griddedInterpolant.
% 
% * Interpolant
%   Interpolating function that you can evaluate at query points.
% 
% * Gridded Data
%   A set of points that are axis-aligned and ordered.
% 
% * Scattered Data
%   A set of points that have no structure among their relative locations.
% 
% * Full Grid
%   A grid represented as a set of arrays. For example, you can create a
%   full grid using ndgrid. 
%   
% * Grid Vectors
%   A set of vectors that serve as a compact representation of a grid in
%   ndgrid format. 
%   For example, [X,Y] = ndgrid(xg,yg) returns a full grid in the matrices
%   X and Y. You can represent the same grid using the grid vectors xg and
%   yg.  
%