function result = isaxes(obj)
%ISAXES True for valid graphics axes.
%  ISAXES(H) returns an array that contains 1s (true) where the elements
%   of H are handles to existing graphics objects and 0s (false) where 
%   they are not graphics objects or are deleted graphics objects.

result = isgraphics(obj, 'axes');
