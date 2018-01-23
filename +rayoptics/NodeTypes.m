classdef NodeTypes < uint8
    %NODETYPES Enumerates categories of ray-entity interaction nodes.
    % Convertible to UINT8 for use in built-in functions like ACCUMARRAY.
    enumeration
        Reflection(1)
        Sink(2)
        Source(3)
        Transmission(4)
    end    
end
