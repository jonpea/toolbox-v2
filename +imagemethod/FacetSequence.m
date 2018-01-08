classdef FacetSequence < sequence.Sequence
    
    properties (SetAccess = immutable)
        Arity
        NumFacets
        NumTuples
        Type = 'double'
    end
    
    properties (SetAccess = private)
        Index
    end
    
    methods
        function obj = FacetSequence(numfacets, arity)
            narginchk(2, 2)
            assert(isnumeric(numfacets) && isscalar(numfacets))
            assert(isnumeric(arity) && isscalar(arity))
            obj.Arity = arity;
            obj.NumFacets = numfacets;
            obj.NumTuples = rayoptics.imagemethodcardinality(numfacets, arity);
            obj.Index = 0;
        end
        
        function tf = hasnext(obj)
            tf = obj.Index < obj.NumTuples;
        end
        
        function element = getnext(obj)
            assert(hasnext(obj))
            obj.Index = obj.Index + 1;
            element = rayoptics.imagemethodsequence( ...
                obj.Index, obj.NumFacets, obj.Arity);
        end
        
    end
    
end
