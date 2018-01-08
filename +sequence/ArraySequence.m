classdef ArraySequence < sequence.Sequence
    %ARRAYSEQUENCE Explicit sequence based on array type.
    %
    % See also SEQUENCE.
    
    properties (SetAccess = private)
        Offset
    end
    
    properties (SetAccess = immutable, Hidden = true)
        Data
        Length
        Type
    end
    
    methods
        
        function obj = ArraySequence(data)
            obj.Offset = 0;
            obj.Length = numel(data);
            obj.Data = data;
            obj.Type = class(data);
        end
        
        function tf = hasnext(obj)
            tf = obj.Offset < obj.Length;
        end
        
        function element = getnext(obj)
            obj.Offset = obj.Offset + 1;
            element = obj.Data(obj.Offset);
        end
        
        function elements = take(obj, n)
            n = min(n, obj.Length - obj.Offset);
            indices = obj.Offset + (1 : n);
            elements = num2cell(obj.Data(indices));
            obj.Offset = obj.Offset + n;
        end
        
    end
    
end
