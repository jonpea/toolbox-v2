classdef NestedSequence < sequence.Sequence
    
    properties (SetAccess = immutable)
        Extractor
        UpperSequenceIsEmpty
        UpperSequence
        LowerSequenceGenerator
        Type = 'cell'
    end
    
    properties (SetAccess = private)
        Counter % purely for the benefit of clients
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
                obj.prepareNextLower
            end
        end
        
        function tf = hasnext(obj)
            if hasnext(obj.LowerSequence)
                % Elements remain in nested sequence
                tf = true;
            elseif ~hasnext(obj.UpperSequence)
                % Both sequences are exhausted
                tf = false;
            else
                % Upper sequence is not exhausted
                obj.prepareNextLower
                tf = hasnext(obj); % recusive call
            end
            
        end
        
        function element = getnext(obj)
            assert(hasnext(obj))
            obj.Counter = obj.Counter + 1; % must come first... [*]
            element = obj.Extractor( ...
                obj.Counter, ... % ... before next use [*]
                obj.UpperElement, ...
                getnext(obj.LowerSequence));
        end
        
    end
    
    methods (Access = private)
        function prepareNextLower(obj)
            obj.UpperElement = getnext(obj.UpperSequence);
            obj.LowerSequence = obj.LowerSequenceGenerator(obj.UpperElement);
            assert(issequence(obj.LowerSequence), ...
                'Generator must return an instance of Sequence.')
            if ~hasnext(obj.LowerSequence)
                if hasnext(obj.UpperSequence)
                    obj.prepareNextLower % recursive call
                end
            end
            % Postcondition:
            % "Either we are ready to return the next lower
            % element or the nested sequence is exhausted".
            assert( ...
                hasnext(obj.LowerSequence) || ...
                ~hasnext(obj.UpperSequence))
        end
    end
    
end

function tf = issequence(s)
tf = isa(s, 'sequence.Sequence');
end
