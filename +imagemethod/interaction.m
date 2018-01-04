classdef interaction < uint8
    %INTERACTION Enumerates categories of ray-wall interactions.
    % Convertible to UINT8 for use in built-in functions like ACCUMARRAY.
    enumeration
        Reflection(1)
        Sink(2)
        Source(3)
        Transmission(4)
    end    
end
