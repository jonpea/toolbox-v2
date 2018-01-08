classdef axisalignedbounds
    
    properties
        Lower
        Upper
    end
    
    methods
        
        function obj = axisalignedbounds(lower, upper)
            assert(ismember(nargin, [0, 2]))
            if nargin == 2
                assert(ismatrix(lower))
                assert(ismatrix(upper))
                assert(isequal(size(lower), size(upper)))
                obj.Lower = lower;
                obj.Upper = upper;
            end
        end
        
        function c = incenter(obj)
            c = 0.5*(obj.Lower + obj.Upper);
        end
        
        function obj = union(obj, other)
            obj.Lower = min(obj.Lower, [], 1);
            obj.Upper = max(obj.Upper, [], 1);
            if nargin == 2
                assert(arecompatible(obj, other))
                obj = union([obj; union(other)]); %#ok<LTARG>
            end
        end
        
        function obj = intersect(obj, other)
            obj.Lower = max(obj.Lower, [], 1);
            obj.Upper = min(obj.Upper, [], 1);
            if nargin == 2
                assert(arecompatible(obj, other))
                obj = intersect([obj; intersect(other)]); %#ok<LTARG>
            end
        end
        
        function result = vertcat(obj, other)
            assert(arecompatible(obj, other))
            result = new( ...
                [obj.Lower; other.Lower], ...
                [obj.Upper; other.Upper]);
        end
        
        function other = subsref(obj, subscript)
            if isscalar(subscript) && strcmp(subscript.type, '()')
                rows = subscript.subs{1};
                other = new(obj.Lower(rows, :), obj.Upper(rows, :));
                return
            end
            other = builtin('subsref', obj, subscript);
        end
                
    end
    
end

function obj = new(varargin)
obj = feval(mfilename, varargin{:});
end

function result = arecompatible(obj, other)
result = size(obj, 2) == size(other, 2);
end
