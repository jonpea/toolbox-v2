classdef material < double
    %MATERIAL Enumerates types of materials.
    
    enumeration

        CeilingLayer(1)
        FloorLayer(2)
        
        Concrete(3)
        GibCavity(4)
        Glass(5)
        Steel(6)        
        Wood(7)
        
        Unknown(nan)
        
    end
    
end
