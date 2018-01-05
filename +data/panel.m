classdef panel < double
    %PANEL Enumerates types of scene panel.
    
    enumeration

        Ceiling(1)
        Floor(2)
        
        % 3D door
        SteelDoor(3)
        WoodenDoor(4) 
        
        % 2D door types
        DoorInConcrete(5) 
        DoorInGibCavity(6)
        DoorToLift(7)
        
        ConcreteWall(8)
        GibWall(9)
        GlassWindow(10)
       
        Unknown(nan)
        
    end
    
end
