function [a, r] = unit(a, varargin)
%UNIT Unit vector associated with a given direction.
%   UNIT(A) returns the matrix of unit vectors
%             A(:,i)/NORM(A(:,i)) for each
%   column I of a matrix A with multiple rows.
%
%   If A has one row, it returns the row vector A/NORM(A).
% 
%   If A has multiple dimensions, the operation applies across the
%   first array dimension with size not equal to 1.
%
%   UNIT(A,DIM) applies over dimension DIM.
%
%   [U,R]=UNIT(A, ...) returns the scale factors R such that A == U.*R.
%
%   See also NORM.

import sx.leaddim
import sx.matfun.norm

narginchk(1, 2)

dim = leaddim(size(a), varargin{:});
r = sx.matfun.norm(a, 2, dim);

a = bsxfun(@rdivide, a, r); % Suitable since R2007a
%a = a./r; % Suitable since R2017a
