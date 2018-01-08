function evaluator = framefunctionnew(functions, frames, facetofunction)

narginchk(2, 3)

if ~iscell(functions)
    functions = {functions};
end

if nargin < 3 || isempty(facetofunction)
    assert(ndebug || isscalar(functions))
    facetofunction = ones(size(frames, 1), 1);
end

% Preconditions
import contracts.ndebug
import datatypes.isfunction
assert(ndebug || isfvframe(frames))
assert(ndebug || iscell(functions))
assert(ndebug || all(cellfun(@isfunction, functions)))
assert(ndebug || all(ismember(unique(facetofunction), 1 : numel(functions))))

    function gain = evaluate(faceindices, directions)

        import contracts.ndebug
        assert(ndebug || isvector(faceindices))
        assert(ndebug || ismatrix(directions))
                
        % Transform global Cartesian coordinates to local 
        % Cartesian coordinates relative to faces' local frames 
        % via "local(i, j) = dot(map(face(i), :, j), global(:))".
        localdirections = reshape( ...
            matfun.dot(frames(faceindices, :, :), directions, 2), ...
            numel(faceindices), []);
        
        % Angles relative to local frame
        angles = cartesiantoangularnew(localdirections);

        gain = indexedunary( ...
            functions, ...
            facetofunction(faceindices), ...
            angles);

    end

evaluator = @evaluate;

end

% -------------------------------------------------------------------------
function result = isfvframe(f)
%ISFVFRAME True for unit frames stored by rows.
% See also FVFRAMES.
unit = 1.0;
tol = eps(10*unit); % relative to 1.0
result = ...
    isnumeric(f) ...
    && ndims(f) == 3 ...
    && ismember(size(f, 2), 2 : 3) ...
    && size(f, 2) == size(f, 3) ...
    && all(ops.vec(abs(matfun.norm(f, 2, 2) - unit)) < tol);
end
