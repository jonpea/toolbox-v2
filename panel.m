classdef panel < double
    %PANEL Enumerates types of scene panel.
    
    enumeration

        Ceiling(1)
        Floor(2)
        
        % 3D door
        Steel(3)
        Wood(4) 
                
        Concrete(5)
        Gib(6)
        Glass(7)
       
        Unknown(nan)
        
    end
    
end
