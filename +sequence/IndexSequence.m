classdef IndexSequence < sequence.Sequence
    %INDEXSEQUENCE Implicit uniformly-spaced sequence.
    %
    % See also SEQUENCE.
    
    properties (SetAccess = private)
        Index
        NumStepsLeft
    end
    
    properties (Hidden = true, SetAccess = immutable)
        StepSize
        Type
    end
    
    methods
        
        function obj = IndexSequence(varargin)
            import sequence.colonparts
            [start, step, stop] = colonparts(varargin{:});
            obj.Index = start;
            obj.StepSize = step;
            obj.NumStepsLeft = max(0, fix((stop - start)/step) + 1);
            obj.Type = class(start);
        end
        
        function tf = hasnext(obj)
            tf = 0 < obj.NumStepsLeft;
        end
        
        function element = getnext(obj)
            assert(hasnext(obj))
            element = obj.Index;
            obj.Index = obj.Index + obj.StepSize;
            obj.NumStepsLeft = obj.NumStepsLeft - 1;
        end
        
        function elements = take(obj, n)
            n = min(n, obj.NumStepsLeft);
            elements = num2cell(obj.Index + obj.StepSize*(0 : n - 1));
            obj.Index = obj.Index + obj.StepSize*n;
            obj.NumStepsLeft = obj.NumStepsLeft - n;
        end
        
    end
    
end
