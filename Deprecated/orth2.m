function [unit1, unit2, r11, r12, r22] = orth2(column1, column2, varargin)
% ORTH2 Orthogonal-triangular decomposition of pairs of vectors.
% [Q1,Q2,R11,R12,R22] = ORTH2(V1,V2,2) uses the Gram-Schmidt process
% (sequential orthogonalization) to compute the orthogonal-triangular
% decomposition
%    [V1(k,:)', V2(k,:)']
%  = [Q1(k,:)', Q2(k,:)']*[R11(k), R12(k);
%                               0, R22(k)]
%  = [Q1.*R11, Q1.*R12 + Q2.*R22]
% with Qk'*Qk = EYE(2)
% across the columns (dimension 2) of V1 and V2.
%
% [Q1,Q2,R11,R12,R22] = ORTH2(V1,V2,DIM) applies to any
% dimension DIM in 1:NDIMS(V1) of V1 and V2.
%
%
% Example:
% >> V1 = rand(15, 3);
% >> V2 = rand(15, 3);
% >> [Q1, Q2, R11, R12, R22] = orth2(V1, V2, 2);
%
% >> norm(V1 - Q1.*R11)
% ans =
%    1.1102e-16
%
% >> norm(V2 - Q1.*R12 - Q2.*R22)
% ans =
%    3.9252e-17
%
% See also QR, ORTH.

narginchk(2, 3)
assert(ismatrix(column1))
assert(ismatrix(column2))
assert(isequal(size(column1), size(column2)))

% Default dimension
dim = sx.leaddim(column1, varargin{:});

% Gram-Schmidt procedure
% 1. column1 =: unit1*r11
% 2. column2 =: unit1*r22 + r (r is orthogonal to unit1)
% 3.       r =: unit2*r22
% i.e.
% [column1, column2] = [unit1*r11, unit1*r12 + unit2*r22]
%                    = [unit1*r11 + unit2*0, unit1*r12 + unit2*r22]
%                    = [unit1, unit2] * [r11, r12]
%                                       [  0, r22]
%
[unit1, r11] = matfun.unit(column1, dim);
r12 = dot(column2, unit1, dim);
[unit2, r22] = matfun.unit(column2 - unit1.*r12, dim);
