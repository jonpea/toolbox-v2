function fun = reflectionPoints(scene)
    function [pairindices, pathPoints] = compute(sourcePoints, sinkPoints, faceIndices)
        [pairindices, pathPoints] = rayoptics.imagemethod( ...
            scene.IntersectFacet, ...
            scene.Mirror, ...
            faceIndices, ...
            sourcePoints, ...
            sinkPoints);
    end
fun = @compute;
end
