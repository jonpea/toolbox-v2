function antennae

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
    function dBW = isotropicPattern(index, directions) %#ok<DEFNU>
        assert(all(ismember(index, 1 : 2))) % "two antennae"
        assert(numel(index) == size(directions, 1)) % "one : one"
        arguments.unused(directions) % "isotropic"
        dBW = zeros(size(index)); % preallocate output
        dBW(index == 1) = -10; % gain for "dry walls"
        dBW(index == 2) = -50; % gain "concrete walls"
    end

%%
% The definition above would be suitable for a pair of isotropic antennae;
% note that the matrix of |directions| is unused.
axis1 = [ -1  0; -1  0];
axis2 = [  0  1;  0  1];
frame = cat(3, axis1, axis2);

end
