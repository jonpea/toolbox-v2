classdef Sequence < handle
    %SEQUENCE Provides an iterator over a sequence.
    %   Interface modeled on matlab.mapreduce.ValueIterator.
    %
    % See also MATLAB.MAPREDUCE.VALUEITERATOR.
    
    properties (Abstract = true, SetAccess = immutable)
        Type
    end
    
    methods (Abstract = true)
        
        tf = hasnext(obj)
        
        element = getnext(obj)
        
    end
    
    methods
        
        function elements = take(obj, n)
            assert(isscalar(n) && isnumeric(n) && 0 <= n)
            % NB: The caller may well have used a conservative upper-bound 
            % (e.g. intmax) to specify that all elements be extracted.
            elements = cell(1, min(n, 5));
            for i = 1 : n
                if hasnext(obj)
                    elements{i} = getnext(obj);
                else
                    elements(i : end) = []; 
                    break
                end
            end
        end
        
        function values = array(obj, n)
            %ARRAY Extract contents into array.
            %   This method is not intended for long sequences.
            if nargin < 2
                n = intmax;
            end
            values = cast(reshape([], 1, 0), obj.Type);
            while hasnext(obj) && 0 < n
                values(end + 1) = getnext(obj);  %#ok<AGROW>
                n = n - 1;
            end
        end
        
        function values = cell(obj, n)
            %CELL Extract contents into cell array.
            %   This method is not intended for long sequences.
            if nargin < 2
                n = intmax;
            end
            values = {};
            while hasnext(obj) && 0 < n
                values{end + 1} = getnext(obj);  %#ok<AGROW>
                n = n - 1;
            end
        end
        
    end
    
end
