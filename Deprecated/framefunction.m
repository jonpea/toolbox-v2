function evaluator = framefunction(functions, frames, facetofunction)

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
assert(ndebug || isfvframe(frames))
assert(ndebug || iscell(functions))
assert(ndebug || all(cellfun(@isfunction, functions)))
assert(ndebug || all(ismember(unique(facetofunction), 1 : numel(functions))))

    function gain = evaluate(faceindices, directions)

        assert(size(directions, 2) == 2, ...
            'Jon: For 3D problems, you should probably use framefunctionnew!')
        
        assert(isvector(faceindices))
        assert(ismatrix(directions))
                
        % Transform global Cartesian coordinates
        % to those relative to faces' local frames
        localdirections = applytranspose( ...
            frames(faceindices, :, :), directions);
        
        % Angles relative to local frame
        angles = cartesiantoangular(localdirections);

        gain = funfun.indexedunary( ...
            functions, ...
            facetofunction(faceindices), ...
            angles);

    end

evaluator = @evaluate;

end
