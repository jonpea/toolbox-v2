function normals = fvnormals(faces, vertices)
[edge1, edge2] = fvtangents(faces, vertices);
normals = unit(cross(edge1, edge2));
