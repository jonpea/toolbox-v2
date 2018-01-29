classdef Materials < double
    %MATERIALS Enumerates material types for descriptive indexing.
    enumeration
        Ceiling(1)
        Floor(2)
        Steel(3)
        Wood(4)
        Concrete(5)
        Gib(6)
        Glass(7)
        Unknown(nan) % illegal index
    end
end
