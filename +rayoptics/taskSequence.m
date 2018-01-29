function tasks = taskSequence(numFacets, lengths)
upperSequence = sequence.ArraySequence(lengths);
    function sequence = generateLowerSequence(length)
        % Input argument is current element in "upper sequence"
        sequence = imagemethod.FacetSequence(numFacets, length);
    end
    function task = extractFromLower(counter, length, sequence)
        arguments.unused(length)
        task = {
            counter ... % global step counter
            sequence ... % candidate face indices
            };
    end
tasks = sequence.NestedSequence( ...
    upperSequence, ...
    @generateLowerSequence, ...
    @extractFromLower);
end
