classdef quadscene < abstractscene
    
    properties (SetAccess = immutable)
        FaceOrigin
        FaceNormal
        FaceOffset
    end
    
    properties (SetAccess = immutable, Hidden = true)
        OffsetToLocalMap
    end
    
    methods
        
        function obj = quadscene(faces, vertices)
            
            narginchk(2, 2)
            assert(size(faces, 2) == 2^(size(vertices, 2) - 1))
            
            numdimensions = size(vertices, 2);
            
            if numdimensions == 3 && ~fvrhomboid(faces, vertices)
                warning([mfilename, ':NonRhomboid'], ...
                    'Some facets are not rhomboid')
            end
            
            [origin, normal, ~, map] = reference.frames(faces, vertices);
            
            obj.FaceOrigin = origin;
            obj.FaceNormal = normal;
            obj.FaceOffset = dot(obj.FaceNormal, obj.FaceOrigin, 2);
            obj.OffsetToLocalMap = map;
            
        end
        
        function [selected, uv] = filter(obj, faceid, projection)
            
            narginchk(3, 3)
            assert(ndebug || size(faceid, 1) == size(projection, 1))
            assert(ndebug || ismember(size(projection, 2), 2 : 3))
            
            offset = projection - obj.FaceOrigin(faceid, :);
            uv = squeeze( ...
                dotsx(obj.OffsetToLocalMap(faceid, :, :), offset, 2));
            selected = all(0 <= uv & uv <= 1, 2);
            
        end
        
    end
    
end