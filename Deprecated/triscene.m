classdef triscene < abstractscene
    
    properties (SetAccess = immutable)
        FaceOrigin
        FaceNormal
        FaceOffset        
    end
    
    properties (SetAccess = immutable, Hidden = true)
        Triangulation
    end
    
    methods
        
        function obj = triscene(tri, varargin)
            narginchk(1, 2)
            if nargin == 2
                tri = triangulation(tri, varargin{:});
            end
            obj.Triangulation = tri;
            obj.FaceNormal = obj.Triangulation.faceNormal();
            obj.FaceOrigin = tri.Points(tri.ConnectivityList(:, 1), :);
            obj.FaceOffset = dot(obj.FaceNormal, obj.FaceOrigin, 2);
        end

        function varargout = filter(obj, varargin)
            [varargout{1 : max(nargout, 1)}] = ...
                trifilter(obj.Triangulation, varargin{:});
        end
        
    end
    
end
