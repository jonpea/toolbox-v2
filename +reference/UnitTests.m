classdef UnitTests < matlab.unittest.TestCase
    
    properties (ClassSetupParameter)
        generator = {'twister'}
    end
    
    properties (MethodSetupParameter)
        seed = {0}
    end
    
    properties (TestParameter)
        numdimensions = {2, 3}
        classname = {'single', 'double'}
        numpoints = {0, 1, 5}
        numfaces = {0, 1, 5}
    end
    
    methods (TestClassSetup)
        function ClassSetup(testCase, generator)
            originalstate = rng;
            testCase.addTeardown(@rng, originalstate)
            rng(0, generator)
        end
    end
    
    methods (TestMethodSetup)
        function MethodSetup(testCase, seed)
            originalstate = rng;
            testCase.addTeardown(@rng, originalstate)
            rng(seed) % retains generator previously specified in constructor
        end
    end
    
    methods (Test, ParameterCombination = 'exhaustive')
        
        function mirrorTest(testcase, numpoints, numdimensions, classname)
            point = rand(numpoints, numdimensions, classname); % arbitrary point
            normal = unitrows(randn(1, numdimensions, classname)); % normal to hyperplane
            offset = -ones(classname); % arbitrary value (distinct from 0 and 1, say)
            mirrored = reference.mirror(point, normal, offset);
            projected = 0.5*(point + mirrored); % projection of point onto hyperplane
            direction = unitrows(point - mirrored); % direction of projection
            testcase.verifyEqual( ...
                abs(dotrows(normal, direction)), ...
                ones(numpoints, 1, classname), ...
                'RelTol', reltol(classname), ...
                'Vector connecting point to mirror/projection must align with normal vector')
            testcase.verifyEqual( ...
                dotrows(normal, projected), ...
                repmat(offset, numpoints, 1), ...
                'RelTol', reltol(classname), ...
                'Projected point must satisfy characteristic equation of hyperplane')
        end
        
        function frameLineTest(testcase, numfaces, classname)
            
            twodimensions = 2;
            numverticesperface = 2;
            
            randompoint = @() rand(numfaces, twodimensions, classname);
            vertices = [ randompoint(); randompoint() ];
            faces = reshape(1 : numfaces*numverticesperface, numverticesperface, [])';
            
            [origin, normal, map] = reference.frames(faces, vertices);
            
            testcase.verifySize(origin, [numfaces, twodimensions])
            testcase.verifySize(normal, [numfaces, twodimensions])
            testcase.verifySize(map, [numfaces, twodimensions])
            
            testcase.verifyEqual( ...
                normrows(normal), ...
                ones(numfaces, 1, classname), ...
                'RelTol', reltol(classname), ...
                'Unit normal vector must have unit length')
            
            testcase.verifyEqual( ...
                mapoffset(normal, map), ...
                zeros(numfaces, 1, classname), ...
                'AbsTol', abstol(classname), ...
                'Normal vector is orthogonal to tangent vector')
            
            function local = localcoordinate(vertexid)
                vertex = vertices(faces(:, vertexid), :);
                local = mapoffset(vertex - origin, map);
            end
            
            testcase.verifyEqual( ...
                localcoordinate(1), ...
                zeros(numfaces, 1, classname), ...
                'AbsTol', abstol(classname), ...
                'First vertex maps to 0')
            
            testcase.verifyEqual( ...
                localcoordinate(2), ...
                ones(numfaces, 1, classname), ...
                'AbsTol', abstol(classname), ...
                'Second vertex maps to 1')
            
        end
        
        function frameParallelogramTest(testcase, numfaces, classname)
            
            threedimensions = 3;
            numverticesperface = 4;
            
            randompoint = @() rand(numfaces, threedimensions, classname);
            faceorigin = randompoint(); % origin
            facetip1 = randompoint(); % tip of first axis
            facetip2 = randompoint(); % tip of second axis
            vertices = reshape([
                faceorigin, ...
                facetip1, ...
                facetip1 + facetip2 - faceorigin, ... % "p0 + (p1-p0) + (p2-p0)"
                facetip2
                ]', threedimensions, [])';
            faces = reshape( ...
                1 : numfaces*numverticesperface, ...
                numverticesperface, [])';
            
            [origin, normal, map] = reference.frames(faces, vertices);
            
            testcase.verifySize(origin, [numfaces, threedimensions])
            testcase.verifySize(normal, [numfaces, threedimensions])
            testcase.verifySize(map, [numfaces, threedimensions, threedimensions - 1])
            
            testcase.verifyEqual( ...
                normrows(normal), ...
                ones(numfaces, 1, classname), ...
                'RelTol', reltol(classname), ...
                'Unit normal vector must have unit length')
            
            testcase.verifyEqual( ...
                mapoffset(normal, map), ...
                zeros(numfaces, threedimensions - 1, classname), ...
                'AbsTol', abstol(classname), ...
                'Normal vector is orthogonal to tangent vectors')
            
            function local = vertexlocalcoordinate(vertexid)
                vertex = vertices(faces(:, vertexid), :);
                local = mapoffset(vertex - origin, map);
            end
            
            function e = elemental(varargin)
                e = zeros(numfaces, threedimensions - 1, classname);
                e(:, cell2mat(varargin)) = ones(classname);
            end
            
            testcase.verifyEqual( ...
                vertexlocalcoordinate(1), ...
                elemental(), ...
                'AbsTol', abstol(classname), ...
                'First vertex maps to [0, 0]')
            
            testcase.verifyEqual( ...
                vertexlocalcoordinate(2), ...
                elemental(1), ...
                'AbsTol', abstol(classname), ...
                'Second vertex maps to [1, 0]')
            
            testcase.verifyEqual( ...
                vertexlocalcoordinate(3), ...
                elemental(1, 2), ...
                'AbsTol', abstol(classname), ...
                'Third vertex maps to [1, 1]')
            
            testcase.verifyEqual( ...
                vertexlocalcoordinate(4), ...
                elemental(2), ...
                'AbsTol', abstol(classname), ...
                'Fourth vertex maps to [0, 1]')
            
        end
        
        function frameTriangleTest(testcase, numfaces, classname)
            
            threedimensions = 3;
            numverticesperface = 3;
            
            randompoint = @() rand(numfaces, threedimensions, classname);
            vertices = [randompoint(); randompoint(); randompoint(); ];
            faces = reshape( ...
                1 : numfaces*numverticesperface, ...
                numverticesperface, [])';
            
            [origin, normal, map] = reference.frames(faces, vertices);
            
            testcase.verifySize(origin, [numfaces, threedimensions])
            testcase.verifySize(normal, [numfaces, threedimensions])
            testcase.verifySize(map, [numfaces, threedimensions, threedimensions - 1])

            testcase.verifyEqual( ...
                normrows(normal), ...
                ones(numfaces, 1, classname), ...
                'RelTol', reltol(classname), ...
                'Unit normal vector must have unit length')
            
            function rectangular = vertexlocalcoordinate(vertexid)
                vertex = vertices(faces(:, vertexid), :);
                rectangular = mapoffset(vertex - origin, map);
                % Note: "barycentric = [rectangular, 1 - sum(rectangular, 2)]"
            end
                        
            function e = elemental(varargin)
                % Rows of the identity matrix
                % e.g. "elemental(2)" replicates [0 1 0]
                e = zeros(numfaces, threedimensions - 1, classname);
                e(:, cell2mat(varargin)) = ones(classname);
            end
            
            testcase.verifyEqual( ...
                vertexlocalcoordinate(1), ...
                elemental(), ...
                'AbsTol', abstol(classname), ...
                'First vertex maps to [0, 0]')
            
            testcase.verifyEqual( ...
                vertexlocalcoordinate(2), ...
                elemental(1), ...
                'AbsTol', abstol(classname), ...
                'Second vertex maps to [1, 0]')
            
            testcase.verifyEqual( ...
                vertexlocalcoordinate(3), ...
                elemental(2), ...
                'AbsTol', abstol(classname), ...
                'Third vertex maps to [0, 1]')
            
        end
                
    end
    
end

function tol = reltol(classname)
tol = 10*eps(classname);
end

function tol = abstol(classname)
tol = 100*eps(classname);
end

function rectangular = mapoffset(offset, map)
numdimensions = size(offset, 2);
rectangular = reshape(sum(offset.*map, 2), [], numdimensions - 1);
end
