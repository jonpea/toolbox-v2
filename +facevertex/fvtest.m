function fvtest
runTest('duplicate')
runTest('nan')
end

% -------------------------------------------------------------------------
function runTest(mask)

import facevertex.fv2xy
import facevertex.xy2fv

fprintf('--- testing ''%s'' ---\n', mask)

maxNumSides = 5;
polygon = @(varargin) makePolygon(maxNumSides, varargin{:});

offsets = 0 : 2 : 2*maxNumSides - 1;
p = arrayfun(polygon, 1 : maxNumSides, offsets, offsets);
xData = [p.XData];
yData = [p.YData];
zData = xData + yData;

fv = xy2fv(xData, yData, zData, mask);
[x, y, z] = fv2xy(fv);

disp('Faces:')
disp(fv.Faces)

assert(size(fv.Faces, 1) == numel(p))
assert(size(fv.Faces, 2) == maxNumSides)
assert(size(fv.Vertices, 2) == 3)
assert(isequal(xData, x))
assert(isequal(yData, y))
assert(isequal(zData, z))

figure(1), clf
subplot(1, 2, 1)
xyHandle = patch('XData', xData, 'YData', yData, 'ZData', zData, 'FaceColor', 'red');
configurePlot()

subplot(1, 2, 2)
fvHandle = patch('Faces', fv.Faces, 'Vertices', fv.Vertices, 'FaceColor', 'blue');
configurePlot()

compare = @(name) isequal(fvHandle.(name), xyHandle.(name));
assert(compare('XData'))
assert(compare('YData'))
assert(compare('ZData'))
assert(compare('Vertices'))
assert(compare('Faces') || strcmpi(mask, 'nan'))

end

function p = makePolygon(maxnumvertices, numvertices, xoffset, yoffset)
t = (0 : numvertices - 1)'*2*pi/numvertices;
t(end + 1 : maxnumvertices, 1) = t(end);
p = struct('XData', cos(t) + xoffset, 'YData', sin(t) + yoffset);
end

function configurePlot
axis('equal')
grid('on')
xlabel('x'), ylabel('y'), zlabel('z')
view(-20, 30)
end
