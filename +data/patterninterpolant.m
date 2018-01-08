function [evaluator, interpolant] = patterninterpolant(data, transform, wrap)

narginchk(1, 3)
if nargin < 2
    transform = @identity;
end
if nargin < 3
    wrap = @wrapcircle;
end

import datatypes.isfunction
assert(isstruct(data))
assert(isfunction(transform))
assert(isfunction(wrap))

numcolumns = numel(fieldnames(data));
assert(ismember(numcolumns, 2 : 3))
callbacks = {@interpolant2d, @interpolant3d};
reader = callbacks{numcolumns - 1};
[evaluator, interpolant] = reader(data, transform, wrap);

end

% -------------------------------------------------------------------------
function [evaluator, interpolant] = interpolant2d(data, transform, wrap)

assert(isfield(data, 'phi'))
assert(isfield(data, 'gain'))
assert(all(0 <= data.phi & data.phi <= 360))
assert(all(0 <= data.gain))

interpolant = griddedInterpolant(deg2rad(data.phi), transform(data.gain));
    function result = evaluate(phi)
        if iscell(phi)
            % Accommodate a single grid vector
            assert(isscalar(phi))
            phi = phi{:};
        end
        result = interpolant(wrap(phi));
    end
evaluator = @evaluate;

end

% -------------------------------------------------------------------------
function [evaluator, interpolant] = interpolant3d(data, transform, wrap)

assert(isfield(data, 'phi'))
assert(isfield(data, 'theta'))
assert(isfield(data, 'gain'))
assert(all(0 <= data.phi & data.phi <= 360))
assert(all(0 <= data.theta & data.theta <= 180))
assert(all(0 <= data.gain))

% Convert unstructured rows to structured grid
[theta, phi, gain] = ungrid(data.theta, data.phi, data.gain);

interpolant = griddedInterpolant({
    deg2rad(theta), ... % inclination from the z-axis
    deg2rad(phi) ... % azimuthal angle from x-axis
    }, ...
    transform(gain));

    function c = enwrap(c)
        % Handles the following possibilities:
        % 1. C = {{X, Y}}: grid vectors where size(X, 2) == size(Y, 2) == 1
        % 2. C = {X, Y}: grid matrices where size(X) == size(Y)
        % 3. C = {X}: unstructured points where size(X, 2) == 2
        if ~iscell(c)
            c = wrap(c);
            return
        end
        c = cellfun(@enwrap, c, 'UniformOutput', false);
    end

    function result = evaluate(varargin)
        narginchk(1, 2)
        args = enwrap(varargin);
        result = interpolant(args{:});
    end
evaluator = @evaluate;

end
