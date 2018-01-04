classdef abstractscene < handle
    
    properties (Abstract = true, SetAccess = immutable)
        FaceOrigin
        FaceNormal
        FaceOffset
    end
    
    methods (Abstract = true)
        [selected, facecoordinates] = filter(obj, faceid, projection)
    end
    
    methods
        function varargout = intersect(obj, varargin)
            [varargout{1 : max(1, nargout)}] = raysceneintersect( ...
                obj.FaceNormal, ...
                obj.FaceOffset, ...
                @obj.filter, ...
                varargin{:});
        end        
    end
    
end
