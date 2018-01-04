function result = reflectionsegments(indices)
% C = REFLECTIONSEGMENTS(INDICES) where INDICES(K) is the index of the
% (K)th facet in the sequence of facets defining a reflection path returns
% the cell array such that C{J} contains the none|one|two face indices in
% segment (J) of the sequence.

indices = indices(:);
switch numel(indices)
    case 0
        % Direct ray, no surfaces to ignore
        result = {[]};
    case 1
        % One surface, two ray segments
        result = {indices; indices};
    otherwise
        % "Two surfaces to ignore on each 'interior' segment"
        % e.g. [a, b, c] --> {a; [a b]; [b c]; c}
        result = [
            indices(1);
            num2cell([indices(1 : end - 1), indices(2 : end)], 2);
            indices(end);
            ];
end

if isempty(indices)
    % Direct ray, no surfaces to ignore
    result2 = {[]};
else
    % "Two surfaces to ignore on each 'interior' segment"
    % e.g. [a, b, c] --> {a; [a b]; [b c]; c}
    indices = indices(:);
    result2 = [
        indices(1);
        num2cell([indices(1 : end - 1, :), indices(2 : end, :)], 2);
        indices(end);
        ];
end

assert(isequal(result, result2))

end
