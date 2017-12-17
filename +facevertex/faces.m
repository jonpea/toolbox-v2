function f = faces(f, ~)
narginchk(1, 2)
if isstruct(f)
    f = f.Faces;
end
