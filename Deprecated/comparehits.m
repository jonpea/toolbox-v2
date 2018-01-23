function comparehits(hits1, hits2, faceindices)

assert(numel(hits1) == numel(hits2))
assert(numel(hits1) == numel(faceindices) + 1)

faceidtoignore = reflectionsegments(faceindices);

for i = 1 : numel(hits1)
    
    hit1 = hits1(i);
    hit2 = hits2(i);
    
    select = @(s) [s.RayIndex, s.SegmentIndex, s.FaceIndex];    
    [~, rows1, rows2] = intersect( ...
        select(hit1), select(hit2), 'rows');
    
    compare( ...
        hit2.RayParameter(rows2, :), ...
        hit1.RayParameter(rows1, :))
    compare( ...
        hit2.FaceCoordinates(rows2, :), ...
        hit1.FaceCoordinates(rows1, :))
    compare( ...
        hit2.Point(rows2, :), ...
        hit1.Point(rows1, :))
    
    extra = @(a, i) tabularrows(a, setdiff(1 : tabularsize(a), i));
    extra1 = extra(hit1, rows1);
    extra2 = extra(hit2, rows2);

    numextra1 = tabularsize(extra1);
    numextra2 = tabularsize(extra2);
    numextras = numextra1 + numextra2;
    
    if 0 < numextras
        fprintf('\n=== %u common, %u : %u extras, excl. %s ===\n', ...
            numel(rows1), ...
            tabularsize(extra1), ...
            tabularsize(extra2), ...
            mat2str(faceidtoignore{i}))
    
        if 0 < numextra1
            fprintf('\n### Complete Extras ####\n')
            tabulardisp(extra1)
        end
        
        if 0 < numextra2
            fprintf('\n@@@@ Embree Extras @@@@\n')
            tabulardisp(extra2)
        end
        
        if 5 < numextras
            input('Press any key to continue>');
        end
        
        check = @(s, classname) ...
            assert(all( ...
            isonboundary(s.FaceCoordinates, 1e-5) | ...
            s.RayParameter < 1e-5 ...
            ));
        check(extra1, 'double')
        check(extra2, 'single')
           
    end
    
end

end
