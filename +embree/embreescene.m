classdef embreescene < handle
    
    properties (SetAccess = public, Hidden = true)
        RayBuffers
        HitBuffers
        FaceMasks
        Deleted
        MexHandle % Handle to the underlying C++ class instance
        CompleteScene
    end
    
    properties (SetAccess = immutable)
        Faces
        Vertices
        %Frame
        NumFacets
        HitCapacity
        RayCapacity
        Intersect
        IntersectFacet
        Mirror
    end
    
    methods (Access = public)
        
        function obj = embreescene(faces, vertices, raycapacity, hitcapacity)
            
            narginchk(2, 4)
            
            if nargin < 3 || isempty(hitcapacity)
                hitcapacity = defaultbuffercapacity;
            end
            
            if nargin < 4 || isempty(raycapacity)
                raycapacity = defaultbuffercapacity;
            end
                        
            obj.CompleteScene = scenes.completescene(faces, vertices);
            %obj.Frame = obj.CompleteScene.Frame; % TODO: refactor
            
            obj.Deleted = false;
            obj.Faces = faces;
            obj.Vertices = vertices;
            obj.Intersect = @obj.intersectpaths;
            obj.IntersectFacet = @obj.intersectfacet;
            obj.Mirror = @obj.mirror;
            obj.NumFacets = size(faces, 1);
            
            obj.HitCapacity = hitcapacity;
            obj.RayCapacity = raycapacity;
            
            % Unfortunately, Embree doesn't support a deep copy
            %obj.construct 
        end
        
        function delete(obj)
            if isempty(obj.MexHandle)
                return % underlying C++ object not actually constructed
            end
            if obj.Deleted
                warning( ...
                    contracts.msgid(mfilename, 'MultipleDelete'),...
                    'Multiple calls to delete on a single instance')
                return
            end
            %fprintf('[Deleting Embree BVH @ %u]\n', obj.MexHandle)
            obj.dispatch('delete')
            obj.Deleted = true;
        end
        
        function mirrorpoints = mirror(obj, varargin)
            %MIRROR Mirrors all points through a single specified facet.
            mirrorpoints = obj.CompleteScene.mirror(varargin{:});
        end
        
        function hits = intersectpaths(obj, origins, directions, faceindices)
            import contracts.ndebug
            narginchk(4, 4)
            assert(ndebug || isequal(size(origins), size(directions)))
            assert(ndebug || size(origins, 3) == numel(faceindices) + 1)
            faceidtoignore = imagemethod.reflectionsegments(faceindices);
            for i = 1 : size(origins, 3)
                obj.intersect( ...
                    origins(:, :, i), ...
                    directions(:, :, i), ...
                    faceidtoignore{i});
            end
            hits = obj.extracthits();
        end
        
        function hits = intersectfacet(obj, varargin)
            hits = obj.CompleteScene.intersectfacet(varargin{:});
        end
        
    end
    
    methods (Access = private)
        
        function intersect(obj, origin, direction, maskindices)
            
            narginchk(3, 4)
            
            if nargin < 4
                maskindices = [];
            end
            
            numrays = size(origin, 1);
            
            assert(isequal(size(origin), size(direction)))
            assert(all(maskindices <= size(obj.Faces, 1)))
            assert(size(origin, 1) <= obj.RayCapacity, ...
                'Increase buffer capacity of %u to accommodate %u rays', ...
                obj.RayCapacity, numrays)
            
            foreachray = @(a) repmat(a, numrays, 1);
            
            [tnear, tfar] = imagemethod.raylimits(embree.embreereal);
            tnear = foreachray(tnear);
            tfar = foreachray(tfar);
            
            obj.construct
            obj.allocatebuffers
            
            function setmasks(trueorfalse)
                obj.FaceMasks(maskindices, :) = trueorfalse;
            end
            
            % TODO: Clear entries within Mex file before returning
            obj.RayBuffers.FaceRayRegister(:, 1 : numrays) = false;
            
            % Note: MATLAB's onCleanup function is not applicable here:
            %     e.g. "maskcleaner = onCleanup(@() setmasks(false))"
            % result in the error:
            %     "Attempt to read from or write to already-destroyed
            %  variable 'maskindices' in workspace of an exiting function"
            assert(contracts.ndebug || all(obj.FaceMasks))
            setmasks(false)
            
            assert(isa(obj.HitBuffers.Offset, embree.embreeindex))
            
            numhits = obj.dispatch('intersect', ...
                ... % Ray data
                embree.embreereal(origin), ...                     % 1
                embree.embreereal(direction), ...                  % 2
                embree.embreereal(tnear), ...                      % 3
                embree.embreereal(tfar), ...                       % 4
                ... % Ray buffers for Embree's internal use
                obj.RayBuffers.Mask, ...             % 5
                obj.RayBuffers.Time, ...             % 6
                obj.RayBuffers.FaceCoordinates, ...  % 7
                obj.RayBuffers.RayIndex, ...         % 8
                obj.RayBuffers.MeshIndex, ...        % 9
                obj.RayBuffers.FaceIndex, ...        % 10
                ... % Mask array for registering hits
                obj.RayBuffers.FaceRayRegister, ...  % 11
                ... % Outputs: Hit buffers
                obj.HitBuffers.FaceIndex, ...       % 12
                obj.HitBuffers.RayIndex, ...        % 13
                obj.HitBuffers.MeshIndex, ...       % 14
                obj.HitBuffers.RayParameter, ...    % 15
                obj.HitBuffers.FaceCoordinates, ... % 16
                obj.HitBuffers.FaceNormal, ...      % 17
                obj.HitBuffers.Offset, ...          % 18
                obj.FaceMasks);                     % 19
            
            % Sanity check: This is also checked inside the Mex function
            assert(numrays < obj.HitCapacity, ...
                'Number of hits exceeded allocated hit capacity')
            
            function p = makepoint(rayindex, t)
                p = origin(rayindex, :) + ...
                    bsxfun(@times, direction(rayindex, :), t);
            end
            
            oldoffset = obj.HitBuffers.Offset;
            newoffset = oldoffset + numhits;
            occupiedrows = oldoffset + 1 : newoffset;
            
            obj.HitBuffers.Point(occupiedrows, :) = ...
                makepoint( ...
                obj.HitBuffers.RayIndex(occupiedrows, :), ...
                obj.HitBuffers.RayParameter(occupiedrows, :));
            
            assert(isa(newoffset, embree.embreeindex))
            obj.HitBuffers.Offset = newoffset;
            obj.HitBuffers.Chunks(end + 1) = numhits;
            
            % Reset (clear) all face masks next call
            setmasks(true)
            
        end
        
        function hits = extracthits(obj, reset)
            
            if nargin < 2 ||  isempty(reset)
                reset = true;
            end
            
            numhits = obj.HitBuffers.Offset;
            
            filled = 1 : numhits;
            import contracts.ndebug
            assert(ndebug || all(0 < obj.HitBuffers.FaceIndex(filled)))
            assert(ndebug || all(0 < obj.HitBuffers.RayIndex(filled)))
            assert(ndebug || all(obj.HitBuffers.MeshIndex(filled) == 0)) % "The only mesh has index 0"
            
            function x = extract(x)
                x = double(x(filled, :));
            end
            
            hits.RayIndex = extract(obj.HitBuffers.RayIndex); % already base one: See definition of mask
            hits.SegmentIndex = imagemethod.segmentindices(obj.HitBuffers.Chunks);
            hits.FaceIndex = extract(obj.HitBuffers.FaceIndex); % already base one: See (**)
            hits.Point = extract(obj.HitBuffers.Point);
            hits.RayParameter = extract(obj.HitBuffers.RayParameter);
            hits.FaceCoordinates = extract(obj.HitBuffers.FaceCoordinates);
            
            if reset
                obj.HitBuffers.Offset = embree.embreeindex(0);
                obj.HitBuffers.Chunks = [];
            end
            
        end
        
    end
    
    methods (Access = private)
        
        function varargout = dispatch(obj, command, varargin)
            [varargout{1 : nargout}] = ...
                embree.embreescenemex(command, obj.MexHandle, varargin{:});
        end
        
        function construct(obj)
            if ~isempty(obj.MexHandle)
                return % already constructed
            end
            obj.MexHandle = embree.embreescenemex('new');
            obj.addquads(obj.Faces, obj.Vertices);
            fprintf('[Constructed Embree BVH @ %u]\n', obj.MexHandle)
        end
        
        function allocatebuffers(obj)
            if ~isempty(obj.RayBuffers)
                return % already allocated
            end
            numfaces = obj.NumFacets;
            hitcapacity = obj.HitCapacity;
            raycapacity = obj.RayCapacity;
            raybuffer = @(class, n) zeros(raycapacity, n, class());
            hitbuffer = @(class, n) zeros(hitcapacity, n, class());
            index = @embree.embreeindex;
            real = @embree.embreereal;            
            obj.RayBuffers = struct( ...
                'FaceIndex', raybuffer(index, 1), ...
                'MeshIndex', raybuffer(index, 1), ...
                'RayIndex', raybuffer(index, 1), ...
                'Mask', raybuffer(index, 1), ...  % mask out objects during traversal
                'FaceCoordinates', raybuffer(real, 2), ... % internal use
                'Time', raybuffer(real, 1), ...  % for motion blur
                'FaceRayRegister', false(numfaces, raycapacity));            
            obj.HitBuffers = struct( ...
                'RayIndex', hitbuffer(index, 1), ...
                'FaceIndex', hitbuffer(index, 1), ...
                'MeshIndex', hitbuffer(index, 1), ...
                'RayParameter', hitbuffer(real, 1), ...
                'FaceCoordinates', hitbuffer(real, 2), ...
                'FaceNormal', hitbuffer(real, 3), ...
                'Offset', index(0), ...
                'Chunks', [], ...
                'Point', hitbuffer(real, 3));            
            obj.FaceMasks = true(numfaces, 1);
        end
        
        function addquads(obj, faces, vertices)
            
            assert(size(vertices, 2) == 3)
            assert(size(faces, 2) == 4)
            assert(min(faces(:)) >= 1)
            assert(max(faces(:)) <= size(vertices, 1))
            
            duplicaterows = @(a) size(unique(a, 'rows'), 1) < size(a, 1);
            if duplicaterows(vertices)
                warning( ...
                    contracts.msgid(mfilename, 'DuplicateVertices'), ...
                    'Scene contains duplicate vertices')
            end
            if duplicaterows(sort(faces, 2))
                warning( ...
                    contracts.msgid(mfilename, 'DuplicateFaces'), ...
                    'Scene contains duplicate faces')
            end
            
            % Embree requires a buffer for 4-alignment
            vertices(:, 4) = nan;
            
            id = obj.dispatch('addmesh', ...
                embree.embreeindex(faces - 1)', ...
                embree.embreereal(vertices)');
            assert(0 == id) % Sanity check: Embree invariant
            
        end
        
    end
    
end

function n = defaultbuffercapacity
n = 1e4;
end
