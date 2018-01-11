function y = applytranspose(a, x)
%APPLYTRANSPOSE Apply transpose of square matrices to vectors.
% APPLYTRANSPOSE(A,X) computes SQUEEZE(A(K,:,:))'*SQUEEZE(X(K,:))'
% for each K in 1:SIZE(X,1).
% Note that A(K,I,J) contains the "row I, column J".

narginchk(2, 2)

if size(a, 1) == 1
    % Explicit singleton expansion on first dimension
    a = repmat(a, size(x, 1), 1);
end

shape = size(a);
assert(shape(1) == size(x, 1))
assert(shape(2) == size(x, 2))

% NB: Specification of the second dimension is essential 
% because e.g. 
%     >> size(reshape(zeros(0, 1, 2), 0, []))
%     ans =
%          0     0
% i.e. "0x0" rather than "0x2".
y = reshape(sum(bsxfun(@times, a, x), 2), shape(1), shape(2));
%y = reshape(sum(a.*x, 2), shape(1), shape(2));