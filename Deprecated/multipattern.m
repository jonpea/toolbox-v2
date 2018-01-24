function evaluator = multipattern(functions, frames, facetofunction)

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

    function gain = evaluate(faceIndices, xglobal)
        
        import contracts.ndebug
        assert(ismatrix(xglobal))
        
        % Transform global Cartesian- to local Cartesian coordinates
        % Squeeze out the singleton in the direction of the dot product
        xlocal = contract(frames(faceIndices, :, :), xglobal, 2);
        
        % Note to Maintainer:
        % We face a choice between two of the three interfaces
        % supported by griddedInterpolant:
        %  1. F(XY) <- "unstructured points"
        %  2. F(X,Y) <- "full grid"
        % (3. F({X,Y}) <- "grid vectors" is not applicable)
        %
        % We choose 1. because it imposes no needless expense
        % when the inner function is constant.
        gain = funfun.indexedunary( ...
            functions, ...
            facetofunction(faceIndices), ...
            xlocal);
        
    end

evaluator = @evaluate;

end

function c = contract(a, b, dim)
narginchk(3, 3)
c = elmat.squeeze(specfun.dot(a, b, dim), dim);
end
