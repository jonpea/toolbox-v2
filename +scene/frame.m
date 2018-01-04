function abc = frame(a, b)

narginchk(1, 2)

switch size(a, 2)
    
    case 2
        assert(nargin == 1)
        a = unit(a, 2);
        % Align zenith with x-axis
        abc = cat(3, a, perp(a)); 

    case 3
        % if nargin == 1
        %     % Default is suitable for "2.5-dimensional" frames
        %     assert(a(3) == 0, 'The single argument must lie in the plane')
        %     b = repmat([0, 0, 1], size(a, 1), 1);
        % end
        % assert(isequal(size(a), size(b)))
        % a = unit(a, 2);
        % b = unit(b, 2);
        % % "a is [1 0 0]" ==> "frame is standard frame"
        % abc = cat(3, a, perp(b, a), b);
        if nargin == 1
            b = perp(a);
        end
        assert(isequal(size(a), size(b)))
        a = unit(a, 2);
        b = unit(b, 2);
        % "a is [1 0 0]" ==> "frame is standard frame"
        abc = cat(3, a, b, perp(b, a));
        
    otherwise
        error('Argument(s) must have 2 or 3 columns')
        
end
