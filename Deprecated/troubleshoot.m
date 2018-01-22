import specfun.todb

tol = 1e-13;
iname = 'yzg0012dinteractions.mat';
pname = 'yzg0012dpowers.mat';

warning('off', 'MATLAB:dispatcher:UnresolvedFunctionHandle')
loadOld = @(filename) load(fullfile('..', 'toolbox', filename));
old.Interactions = loadOld(iname);
old.Powers = loadOld(pname);

new.Interactions = load(iname);
new.Powers = load(pname);

iold = old.Interactions.interactions.Data;
inew = new.Interactions.interactions.Data;

pold = old.Powers;
pnew = new.Powers;

assert(isequal(pold.gridx, pnew.gridx))
assert(isequal(pold.gridy, pnew.gridy))
for i = 1 : size(pold.gridp, 3)
    %diffw = abs(pold.gridp(:, :, i) - pnew.gridp(:, :, i))
    diffdbw = abs(todb(pold.gridp(:, :, i)) - todb(pnew.gridp(:, :, i)))
end

%assert(isequal(iold.InteractionType, inew.InteractionType)) % requires classdef/enumeration loader
assert(isequal(iold.FreeDistance, inew.FreeDistance))
assert(isequal(iold.FinalDistance, inew.FinalDistance))
assert(norm(iold.SourceGain - inew.SourceGain, inf) < tol)
assert(isequal(iold.SinkGain, inew.SinkGain))
assert(isequal(iold.Direction, inew.Direction))

fprintf(iofun.stderr, 'Jon: This is the problem!\n')
norm(iold.Position - inew.Position, inf) 
%[sortrows(iold.Position), sortrows(inew.Position), sortrows(iold.Position)-sortrows(inew.Position)]
assert(norm(sortrows(iold.Position) - sortrows(inew.Position), inf) < tol)

