function [evaluator, interpolant] = patterninterpolantnew(data, varargin)

narginchk(1, nargin)
assert(ismember(numel(fieldnames(data)), 2 : 3))

parser = inputParser;
parser.addParameter('OutputTransform', @elfun.identity, @datatypes.isfunction)
parser.addParameter('InputTransform', @specfun.wrapcircle, @datatypes.isfunction)
parser.parse(varargin{:})
options = parser.Results;

switch numel(fieldnames(data))
    case 2
        reader = @interpolant2d;
    case 3
        reader = @interpolant3d;
end

[evaluator, interpolant] = reader( ...
    data, options.OutputTransform, options.InputTransform);

end

% -------------------------------------------------------------------------
function [evaluator, interpolant] = interpolant2d(data, outputtransform, inputtransform)

assert(isfield(data, 'phi'))
assert(isfield(data, 'gain'))
assert(all(0 <= data.phi & data.phi <= 360))
assert(all(0 <= data.gain))

interpolant = griddedInterpolant(deg2rad(data.phi), outputtransform(data.gain));
    function result = evaluate(phi)
        if iscell(phi)
            % Accommodate a single grid vector
            assert(isscalar(phi))
            phi = phi{:};
        end
        result = interpolant(inputtransform(phi));
    end
evaluator = @evaluate;

end

% -------------------------------------------------------------------------
function [evaluator, interpolant] = interpolant3d(data, outputtransform, inputtransform)

assert(isfield(data, 'phi'))
assert(isfield(data, 'theta'))
assert(isfield(data, 'gain'))
assert(all(0 <= data.phi & data.phi <= 360))
assert(all(0 <= data.theta & data.theta <= 180))
assert(all(0 <= data.gain))

% Convert unstructured rows to structured grid
[phi, theta, gain] = points.fullgrid.ungrid(data.phi, data.theta, data.gain);

interpolant = griddedInterpolant({
    deg2rad(phi), ... % azimuthal angle from x-axis
    deg2rad(theta) ... % inclination from the z-axis
    }, ...
    outputtransform(gain));

    function c = enwrap(c)
        % Handles the following possibilities:
        % 1. C = {{X, Y}}: grid vectors where size(X, 2) == size(Y, 2) == 1
        % 2. C = {X, Y}: grid matrices where size(X) == size(Y)
        % 3. C = {X}: unstructured points where size(X, 2) == 2
        if ~iscell(c)
            c = inputtransform(c);
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
