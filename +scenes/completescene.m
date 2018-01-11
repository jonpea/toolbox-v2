classdef completescene < handle
    
    properties (SetAccess = immutable, Hidden = true)
        % These members are transposed/permuted for Mex function
        FaceOriginsTransposed
        FaceNormalsTransposed
        FaceOffsetsTransposed
        FaceMapsTransposed
    end
    
    properties (Hidden = true)
        FaceMasksTransposed
    end
    
    properties (Hidden = true)
        Buffer
        Offset
        Chunks
    end
    
    properties (SetAccess = immutable)
        
        % Original arrays, available for plotting
        Origin
        UnitNormal
        UnitOffset
        Frame
        
        % Interface for image method
        Intersect
        IntersectFacet
        Mirror
        NumFacets
    end
    
    methods (Access = public)
        
        function obj = completescene(faces, vertices, buffersize)
            
            narginchk(2, 3)
            
            if nargin < 3 || isempty(buffersize)
                % Default buffer capacity
                % NB: This value must be >1 because the MATLAB runtime 
                % appears to reallocate scalars during calls to Mex
                % functions (naturally, we need the buffer to remain 
                % undisturbed throughout the call).
                buffersize = 2;
            end
            
            assert(min(faces(:)) >= 1)
            assert(max(faces(:)) <= size(vertices, 1))
            assert(1 < buffersize, 'Initial capacity *must* exceed 1.')
            
            numdimensions = size(vertices, 2);
            assert(ismember(numdimensions, 2 : 3));
            obj.Buffer = struct( ...
                'FaceIndex', allocate(1, buffersize), ...
                'RayIndex', allocate(1, buffersize),  ...
                'RayParameter', allocate(1, buffersize), ...
                'Point', allocate(numdimensions, buffersize), ...
                'FaceCoordinates', allocate(numdimensions - 1, buffersize));
            obj.Offset = mex.mexindex(0);
            obj.Chunks = []; % dynamic growth to very small size
            
            [origins, normals, unittangents, offsettolocalmaps] = reference.frames(faces, vertices);
            offsets = matfun.dot(normals, origins, 2);
                        
            % Private members
            obj.FaceOriginsTransposed = origins';
            obj.FaceNormalsTransposed = normals';
            obj.FaceOffsetsTransposed = offsets';
            obj.FaceMapsTransposed = permute(offsettolocalmaps, [2 3 1]);
            obj.FaceMasksTransposed = true(1, numel(offsets));
            
            % Public interface
            obj.Origin = origins;
            obj.UnitNormal = normals;
            obj.UnitOffset = offsets;
            obj.Frame = cat(3, normals, unittangents);            
            obj.IntersectFacet = @obj.intersectfacet;
            obj.Intersect = @obj.intersectpaths;
            obj.Mirror = @obj.mirror;
            obj.NumFacets = size(origins, 1);
                       
        end
        
        function mirrorpoints = mirror(obj, points, faceid)
            %MIRROR Mirrors all points through a single specified facet.
            narginchk(3, 3)
            assert(isscalar(faceid))
            normal = obj.FaceNormalsTransposed(:, faceid);
            offset = obj.FaceOffsetsTransposed(faceid);
            normal = normal(:)';
            alpha = (offset - sum(normal.*points, 2)); % "... ./dotrows(n,n)" only if "||n|| ~= 1.0"
            mirrorpoints = points + 2*alpha.*normal;
        end
        
        function hits = intersectpaths(obj, origins, directions, faceindices)
            narginchk(4, 4)
            nargoutchk(1, 1)
            import contracts.ndebug
            assert(ndebug || isequal(size(origins), size(directions)))
            assert(ndebug || size(origins, 3) == numel(faceindices) + 1)
            faceidtoignore = imagemethod.reflectionsegments(faceindices);
            for i = 1 : size(origins, 3)
                obj.intersectSegments( ...
                    origins(:, :, i), ...
                    directions(:, :, i), ...
                    faceidtoignore{i});
            end
            hits = obj.extractHits();
        end
        
        function hits = intersectfacet(obj, origins, directions, faceid)
            
            narginchk(4, 4)
            assert(contracts.ndebug || isscalar(faceid))
            
            % When all but one face is to be discarded, apply filter
            % by reducing mesh to the single specified face.
            obj.intersectionDispatch(origins, directions, faceid)
            hits = obj.extractHits;
            
            % Recover specified face index
            assert(contracts.ndebug || all(hits.FaceIndex == 1))
            hits.FaceIndex(:) = faceid;
            
        end
        
    end
    
    methods (Access = private)
        
        function interactions = intersectSegments(obj, origins, directions, ignore)
            
            narginchk(3, 4)
            
            if nargin < 4
                ignore = [];
            end
            
            % When only a few (one or two) faces are to be discarded,
            % apply the filter via face masks, since indexing with ':'
            % is minimally inexpensive.
            assert(contracts.ndebug || all(obj.FaceMasksTransposed))
            obj.FaceMasksTransposed(ignore) = false;
            obj.intersectionDispatch(origins, directions, ':')
            obj.FaceMasksTransposed(ignore) = true;
            
            if nargout == 1
                interactions = obj.extractHits;
            end
            
        end
        
        function hits = extractHits(obj, reset)
            
            if nargin < 2 ||  isempty(reset)
                reset = true;
            end
            
            numhits = obj.Offset;
            extract = @(a) double(a(:, 1 : numhits)');
            ctomatlab = @(index) index + 1; % "C/C++ to MATLAB"
            
            hits = struct( ...
                ... % Index-valued fields
                'RayIndex', ctomatlab(extract(obj.Buffer.RayIndex)), ...
                'SegmentIndex', imagemethod.segmentindices(obj.Chunks), ...
                'FaceIndex', ctomatlab(extract(obj.Buffer.FaceIndex)), ...
                ... % Real-valued fields
                'Point', extract(obj.Buffer.Point), ...
                'RayParameter', extract(obj.Buffer.RayParameter), ...
                'FaceCoordinates', extract(obj.Buffer.FaceCoordinates));
            
            if reset
                obj.Offset = mex.mexindex(0);
                obj.Chunks = [];
            end
            
        end
        
        function intersectionDispatch(obj, origins, directions, faceid)
            % This helper method comprises operations common to
            %    "intersect rays with a single facet"
            % and
            %    "intersect rays with the entire scene"
            
            narginchk(4, 4)
            
            % Preconditions
            import contracts.ndebug
            assert(ndebug || ismatrix(origins))
            assert(ndebug || ismatrix(directions))
            assert(ndebug || ismember(size(origins, 2), 2 : 3))
            assert(ndebug || isequal(size(origins), size(directions)))
            assert(ndebug || isscalar(faceid)) % "either ':' or one facet"
            assert(ndebug || sum(obj.Chunks) == obj.Offset)
            
            [tnear, tfar] = imagemethod.raylimits(class(origins));
            
            % State variables are loop indices
            % NB: These C/C++ indices start at zero
            [face_loop_id, ray_loop_id] = deal(mex.mexindex(0));            
            
            % To calculate number of hits from offsets
            oldoffset = obj.Offset;
            
            % While candidate intersections remain to be processed...
            while true
                % ... extract as many as fit into available buffer storage
                [success, face_loop_id, ray_loop_id, obj.Offset] = ...
                    scenes.planarintersectionmex( ...
                    ... % Inputs: Scene
                    obj.FaceOriginsTransposed(:, faceid), ...
                    obj.FaceNormalsTransposed(:, faceid), ...
                    obj.FaceOffsetsTransposed(:, faceid), ...
                    obj.FaceMapsTransposed(:, :, faceid), ...
                    obj.FaceMasksTransposed(:, faceid), ...
                    ... % Inputs: Rays
                    origins', ...
                    directions', ...
                    tnear, ...
                    tfar, ...
                    ... % Outputs: Hits
                    obj.Buffer.FaceIndex, ...
                    obj.Buffer.RayIndex, ...
                    obj.Buffer.RayParameter, ...
                    obj.Buffer.Point, ...
                    obj.Buffer.FaceCoordinates, ...
                    obj.Offset, ...
                    ... % State variables: C++ loop indices
                    face_loop_id, ...
                    ray_loop_id); ...
                    
                if success
                    break % if candidates have been processed...
                end
                
                % ... or increase buffer size and continue
                obj.Buffer = structfun( ...
                    @reallocate, obj.Buffer, 'UniformOutput', false);
                
            end
            
            % Prepare for next batch of hits
            numhits = obj.Offset - oldoffset;
            obj.Chunks(end + 1) = numhits;
            
        end
        
    end
    
end

% -------------------------------------------------------------------------
function a = reallocate(a)
%REALLOCATE Double the number of columns in an array.
numcols = 2*size(a, 2);
a(:, end + 1 : numcols) = zeros('like', a);
end

function a = allocate(varargin)
a = repmat(-7777, varargin{:});
end

