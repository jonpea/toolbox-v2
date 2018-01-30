function antennaeOld

%% Specification of antennae and attenuators
% We'll refer to antennae and walls - or anything that is not
% electromagnetically transparent - as _entities_.
%
% A complete specification of an entity requires:
%
% # A location in global Cartesian coordinates; a facet also requires a
% normal vector.
% # A function mapping directions (in global Cartesian coordinates) to
% _gain_ in dBW.
%
% Multiple entities may share a single such gain function: To maximize
% computational efficiency, the function is called only once; its first
% argument specifies which entity each direction vector refers, while
% global Cartesian coordinates of the direction vectors are stored in the
% rows of the second argument.
%
% The specification is provided in the form of a function handle that
% conforms to the interface of the following example:
gainDBW = [-6, -10];
    function dBW = isotropicPattern(indices, directions)
        assert(all(ismember(indices, 1 : 2))) % "two antennae"
        assert(numel(indices) == size(directions, 1)) % "one : one"
        arguments.unused(directions) % "isotropic"
        dBW = zeros(size(indices)); % preallocate output
        dBW(indices == 1) = gainDBW(1); % gain for "dry walls"
        dBW(indices == 2) = gainDBW(2); % gain "concrete walls"
    end

%%
% The definition above would be suitable for a pair of isotropic antennae;
% note that the matrix of |directions| is unused.
axis1 = [ -1  0; -1  0];
axis2 = [  0  1;  0  1];
frame = cat(3, axis1, axis2);

numPatterns = 2;
numDirections = 2;
numRays = 10;
directions = rand(numRays, numDirections) - 0.5;
indices = randi([1, numPatterns], numRays);

dBW = isotropicPattern(indices, directions);

%% 


end
