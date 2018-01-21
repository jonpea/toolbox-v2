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
import datatypes.isfunction
assert(ndebug || isfvframe(frames))
assert(ndebug || iscell(functions))
assert(ndebug || all(cellfun(@isfunction, functions)))
assert(ndebug || all(ismember(unique(facetofunction), 1 : numel(functions))))

    function gain = evaluate(faceindices, directions)

        import contracts.ndebug
        assert(ndebug || isvector(faceindices))
        assert(ndebug || ismatrix(directions))
                
        % Transform global Cartesian- to local Cartesian coordinates 
        % NB: This is compatible with singleton expansion
        %     i.e. face indices or directions may be singleton
        localdirections = specfun.dot(frames(faceindices, :, :), directions, 2);

        % Squeeze out the singleton in the direction of the dot product
        localdirections = elmat.squeeze(localdirections, 2);
        
        % Angles relative to local frame
        angles = cartesiantoangularnew(localdirections);

        tol = 1e-12;
        switch size(directions, 2)
            case 2
                [x, y] = elmat.cols(localdirections);
                assert(norm(cart2pol(x, y) - angles) < tol)
            case 3
                [x, y, z] = elmat.cols(localdirections);
                % NB: This tests no longer applies as 
                % angles are now wrapped to their principle values
                %[azimuth, inclination] = specfun.cart2sphi(x, y, z);
                %assert(norm([azimuth, inclination] - angles) < tol)
        end
        
        gain = funfun.indexedunary( ...
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
unit = ones('like', f);
tol = eps(10*unit); % relative to 1.0
result = ...
    isnumeric(f) ...
    && ndims(f) == 3 ...
    && ismember(size(f, 2), 2 : 3) ...
    && size(f, 2) == size(f, 3) ...
    && all(ops.vec(abs(matfun.norm(f, 2, 2) - unit)) < tol);
end
