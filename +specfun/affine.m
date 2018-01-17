function result = affine(a, b, theta)
%AFFINE Affine combination of two objects
result = (1 - theta).*a + theta.*b;
