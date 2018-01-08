classdef NestedSequence < sequence.Sequence
    
    properties (SetAccess = immutable)
        Extractor
        UpperSequenceIsEmpty
        UpperSequence
        LowerSequenceGenerator
        Type = 'cell'
    end
    
    properties (SetAccess = private)
        Counter
        LowerSequence
        LowerElement
        UpperElement
    end
    
    methods
        function obj = NestedSequence(upper, lowergen, extractor)
            narginchk(2, 3)
            if nargin < 3
                extractor = @deal; 
            end
            assert(issequence(upper))
            assert(datatypes.isfunction(lowergen))
            obj.UpperSequence = upper;
            obj.LowerSequenceGenerator = lowergen;
            obj.Extractor = extractor;
            obj.Counter = 0;
            if hasnext(upper)
                obj.advance
            end
        end
        
        function tf = hasnext(obj)
            if ~issequence(obj.LowerSequence)
                % If UpperSequence was initially empty, then 
                % LowerSequence would not have been instantiated
                tf = false;
                return 
            end
            tf = hasnext(obj.UpperSequence) || hasnext(obj.LowerSequence);
        end
        
        function element = getnext(obj)
            assert(hasnext(obj))
            if ~hasnext(obj.LowerSequence)
                obj.advance
            end
            obj.Counter = obj.Counter + 1;
            element = obj.Extractor( ...
                obj.Counter, ...
                obj.UpperElement, ...
                getnext(obj.LowerSequence));
        end
        
    end
    
    methods (Access = private)
        function advance(obj)
            obj.UpperElement = getnext(obj.UpperSequence);
            obj.LowerSequence = obj.LowerSequenceGenerator(obj.UpperElement);
            assert(issequence(obj.LowerSequence))
        end
    end
    
end

function tf = issequence(s)
tf = isa(s, 'sequence.Sequence');
end
