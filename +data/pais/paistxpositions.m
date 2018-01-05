function varargout = paistxpositions(numdirections)
%PMCTRANSMITTERPOSITIONS Propagation Measurement Campaign transmitter coordinates.

narginchk(0, 2)
nargoutchk(0, 3)

if nargin < 1 || isempty(numdirections)
    numdirections = 3;
end
assert(ismember(numdirections, 2 : 3))

numtransmitters = 14;
data = nan(14, 3);
xycolumns = 1 : 2;
zcolumn = 3;

% All coordinates are stated in meters
data([1, 3, 5, 13], xycolumns) = repmat([5, 13.5], 4, 1); 
data([2, 4, 6, 14], xycolumns) = repmat([13.5, 5], 4, 1); 
data([ 1,  2], zcolumn) = levelheight(6);
data([ 3,  4], zcolumn) = levelheight(7);
data([ 5,  6], zcolumn) = levelheight(8);
data([13, 14], zcolumn) = levelheight(9);

data( 7, xycolumns) = [-42,  3];
data( 8, xycolumns) = [-42, 15];
data( 9, xycolumns) = [-25,  3];
data(10, xycolumns) = [-25, 15];
data(11, xycolumns) = [ -8,  3];
data(12, xycolumns) = [ -8, 15];
data(7 : 12, zcolumn) = levelheight(5);

assert(size(data, 1) == numtransmitters) % invariant/sanity-check
assert(size(data, 2) == 3)

switch nargout
    case {0, 1}
        varargout{1} = data(:, 1 : numdirections);
    case {2, 3}
        varargout{1} = data(:, 1);
        varargout{2} = data(:, 2);
        varargout{3} = data(:, 3);
end

function height = levelheight(level) 
height = pmclevelheight(level);

function m = mm2m(mm)
m = mm/1000;
