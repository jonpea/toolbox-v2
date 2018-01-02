function result = imagemethodcardinality(n, d)
narginchk(2, 2)
result = n.*(n - 1).^(d - 1);
result(d == 0) = 1;
