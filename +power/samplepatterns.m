function samplepatterns(gain, origins, varargin)

parser = inputParser;
parser.addParameter('Azimuth', linspace(0, 2*pi), @isvector)
parser.addParameter('Inclination', default, @isvector)
parser.addParameter('Frame', reshape(eye(3), 1, 3, 3), ...
    @(f) ndims(f) == 3 && size(f, 2) == 3 && size(f, 3) == 3)
parser.addParameter('Units', 'radians', @ischar)
parser.parse(varargin{:})
options = parser.Results;

[numantenna, numdirections] = size(origins);
assert(ismember(numdirections, 2 : 3))

azimuth = options.Azimuth;
inclination = options.Inclination;
frames = options.Frame;

if isequal(inclination, default)
    switch numdirections
        case 2
            inclination = 0.0;
        case 3
            inclination = linspace(0, pi);
    end
end
assert(numdirections == 3 || isequal(inclination, 0.0))

switch validatestring(options.Units, {'degrees', 'radians'})
    case 'degrees'
        azimuth = deg2rad(azimuth);
        inclination = deg2rad(inclination);
end

if size(origins, 1) == 1
    origins = repmat(origins, size(frames, 1));
end

if size(frames, 1) == 1
    frames = repmat(frames, size(origins, 1));
end

[x, y, z] = sphericaltocartesian(azimuth, inclination);
    function result = sample(origin, frame, local)
        result.XOrigin = origin(1);
        result.YOrigin = origin(2);
        result.ZOrigin = origin(3);
        local.xyz = toglobal(frame, [x(:), y(:), z(:)]);
        result.XVector = reshape(local.xyz(:, 1), shape);
        result.YVector = reshape(local.xyz(:, 2), shape);
        result.ZVector = reshape(local.xyz(:, 3), shape);        
    end

result = cellfun(@sample, ...
    num2cell(origins, 2), num2cell(frames, 2 : 3));

end

function result = default
result = sprintf('%s-default', mfilename);
end
