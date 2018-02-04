function [x, lower, upper] = linfracprog( ...
    C, d, F, g, lower, upper, epsilon, A, b, varargin)
%LINFRACPROG Generalized linear-fractional programming.
%   [X,LOWER,UPPER] = LINFRACPROG(C,D,F,G,LOWER,UPPER,EPSILON,A,B) attempts
%   to solve the generalized fractional programming problem (GLFP):
%
%     arg min max((C*X + D)./(F*X + G))  subject to: A*X <= B
%          X
%
%   where [LOWER, UPPER] is an interval that must contain the optimal
%   value of GLFP. If successful, the function returns its estimate X of
%   the solution and tightened bounds on the associated objective value
%   such that (UPPER - LOWER) <= EPSILON.
%
%   LINFRACPROG(C,D,F,G,LOWER,UPPER,EPSILON,A,B,AEQ,BEQ) imposes the
%   additional equality constraints AEQ*X = BEQ on GLFP.
%
%   LINFRACPROG(C,D,F,G,LOWER,UPPER,EPSILON,A,B,AEQ,BEQ,LB,UB) imposes the
%   additional variable bounds LB <= X <= UB on GLFP.
%
%   LINFRACPROG(C,D,F,G,LOWER,UPPER,EPSILON,A,B,AEQ,BEQ,LB,UB,OPTIONS)
%   specifies options that are used internally by LINPROG.
%
%   See also LINPROG.

%
% Note to Maintainer
% ==================
% The algorithm implemented herein is described in the lectures notes for
% EE236A - Linear Programming (Fall Quarter 2013-14)
% by Prof. L. Vandenberghe, UCLA.
% http://www.seas.ucla.edu/~vandenbe/ee236a
%
% See Slides for Lecture 8: Linear-Fractional Optimization:
%   Slide 8-7: "Generalized linear-fractional programming"
%   Slide 8-9: "Bisection algorithm"
%

narginchk(6, 14)

% Preconditions on essential input arguments
assert(isnumeric(C) && ismatrix(C))
assert(isnumeric(F) && ismatrix(F))
assert(isnumeric(d) && iscolumn(d))
assert(isnumeric(g) && iscolumn(g))
assert(isequal(size(C), size(F)))
assert(isequal(size(d), size(g)))
assert(isequal(size(C, 1), numel(d)))
assert(isnumeric(lower) && isscalar(lower))
assert(isnumeric(upper) && isscalar(upper))
assert(lower < upper)

classname = class(C);
n = size(C, 2); % number of variables

% Optional input arguments
if nargin < 7 || isempty(epsilon)
    epsilon = 1e-5*(upper - lower);
end
if nargin < 8 || isempty(A)
    A = zeros(0, n, classname);
end
if nargin < 9 || isempty(b)
    b = zeros(0, 1);
end

% Preconditions on optional input arguments
assert(isnumeric(epsilon) && isscalar(epsilon) && 0 < epsilon)
assert(isnumeric(A) && ismatrix(A))
assert(isnumeric(b) && iscolumn(b))
assert(size(A, 1) == numel(b))
assert(size(A, 2) == n)

% Number of iterations required to reduce width
% "epsilon0 := upper - lower" of initial interval to specified "epsilon"
% if the width is halved with each bisection step:
% i.e. solve "epsilion0*0.5^N == epsilon" for "N" by applying log2()
% to each side of the equation and substituting log2(0.5) == -1.
epsilon0 = upper - lower;
maxiter = ceil(log2(epsilon0/epsilon));

%for i = 1 : ceil(maxiter)
iter = 0;

while true
    
    iter = iter + 1;
    alpha = 0.5*(lower + upper);
    
    % Solve LP feasibility problem
    [x, ~, exitflag] = linprog( ...
        ... % Arbitrary non-zero objective coefficients
        ... % for what is actually a feasibility problem
        -ones(1, n), ...
        ... % GLFP-augmented inequalities in "less-than (<=)" form:
        ... % C*x + d <= alpha*(F*x + g)
        ... %     A*x <= b
        ... % F*x + g >= 0
        [C - alpha*F; A; -F], ...
        [alpha*g - d; b;  g], ...
        ... % Original equalities, bound constraints, and options
        varargin{:});
    
    % Type "doc linprog" complete list of LINPROG's exit flags
    switch exitflag
        case 1 % "LINPROG converged to a solution"
            upper = alpha;
            if maxiter <= iter
                break
            end
        case -2 % "No feasible point found"
            lower = alpha;
        otherwise
            error( ...
                contracts.msgid(mfilename, 'BadBisection'), ...
                'Did not verify feasibility in inner iteration')
    end
    
end

return
