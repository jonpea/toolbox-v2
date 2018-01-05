%function bestpairwisesirtest
clear, rng(0)

runtest(3, 3)
return

maxnumbasestations = 6;

for numbasestations = 2 : maxnumbasestations
    for nummobiles = 2 : numbasestations
        runtest(numbasestations, nummobiles)
    end
end

runtest(3, 3)

% -------------------------------------------------------------------------
function runtest(numbasestations, nummobiles)

% Random gain data
mingaindb = -50;
maxgaindb = -1;
alpha = rand(numbasestations, nummobiles);
pathwisegaindb = (1 - alpha)*mingaindb + alpha*maxgaindb;
pathwisegain = fromdb(pathwisegaindb);

% Solution via iterative balancing
bestsirdb1 = CalculateBestSIR_pairwise(pathwisegain);
[bestsirdb2, txpowerofmobile] = bestpairwisesir(pathwisegain);

fprintf('%ux%u: %g == %g\n', ...
    numbasestations, nummobiles, bestsirdb1, bestsirdb2)
assert(isequaln(bestsirdb1, bestsirdb2))

gflp = uplinksir(pathwisegain, ones(1, nummobiles), true);
% model = glfptogurobi(gflp.c, gflp.d, gflp.c0, gflp.d0);
% params = struct('outputflag', 1);
% result = gurobi(model, params);
%{
glfp(gflp.c, gflp.d, gflp.c0, gflp.d0, ...
    'lb', zeros(nummobiles, 1), 'ub', ones(nummobiles, 1), ...
    'options', optimset('Display', 'off'))
%}

tolfun = 1e-3;
C = gflp.c;
F = gflp.d;
d = gflp.c0;
g = gflp.d0;
n = size(C, 2);
ub = 1e3; % large but finite upper bound; inf doesn't seem to work

sirvec = (C*txpowerofmobile(:)) ./ (F*txpowerofmobile(:));
sir = reshape(sirvec, size(pathwisegain));
sirdbs = todb(sir)
minmaxsirdbs = min(max(sirdbs));
upper = minmaxsirdbs + 2;
lower = minmaxsirdbs - 1;
delta = 0.05;
maxiter = (log(delta/(upper - lower))/log(0.5))

for i = 1 : ceil(maxiter)
    
    if upper - lower < tolfun
        fprintf('** Converged after %u iterations ** \n', i)
        break
    end
    
    alpha = 0.5*(lower + upper);
    fprintf('%g in [%g, %g]...\n', alpha, lower, upper)

    A = [C - alpha*F; -F];
    b = [alpha*g - d; g];
    
    % Solve LP feasibility problem
    [x, fval, exitflag] = linprog( ...
        -ones(1, n), ...
        A, ...           % A
        b, ...           % b
        ones(1, n), ...  % Aeq
        1, ...           % beq (arbitrary nonzero value to eliminate trivial solution)
        zeros(n, 1), ... % lb
        repmat(ub, n, 1), ...  % ub
        optimoptions(@linprog, ...
        'OptimalityTolerance', 1e-10, ...
        'Algorithm', 'dual-simplex'));
    
    switch exitflag
        case 1 % found feasible solution
            upper = alpha;
        case -2 % problem is infeasible
            lower = alpha;
        otherwise
            error([mfilename, ':BadBisection'], ...
                'Did not verify feasibility in inner iteration')
    end
   
    continue
    
end

% Scale for comparison
scale = x(:)\txpowerofmobile(:);
computed = scale*x(:);

disp('Optimal Power:')
tabulardisp(struct( ...
    'Actual', computed(:), ...
    'Expected', txpowerofmobile(:)))
fprintf('%g vs %g\n', todb(alpha), bestsirdb1)
disp('SIR:')
tabulardisp(struct( ...
    'Actual', uplinksir(pathwisegain, computed(:)')', ...
    'Expected', uplinksir(pathwisegain, txpowerofmobile)'))

return % ==================================================================

% Solution as generalized fractional program
gflp = uplinksir(pathwisegain, ones(1, nummobiles), true);
solver = @linprog;
[molp, recover1] = lfptolp( ...
    gflp.c1, gflp.d1, gflp.c2, gflp.d2, ...
    'lb', [], ... zeros(nummobiles, 1), ...
    'ub', [], ... ones(nummobiles, 1), ...
    'solver', func2str(solver), ...
    'options', ...
    optimoptions(solver, ...
    'Display', 'iter', ...
    'Diagnostics', 'on'));
clc

disp('=== original gflp objectives ===')
disp('numerator:')
disp([gflp.c1, gflp.d1])
disp('denominator:')
disp([gflp.c2, gflp.d2])

disp('=== homogenized gflp ===')
disp('objectives:')
disp(molp.f)
disp('inequalities:')
disp([molp.Aineq, molp.bineq])
disp('equalities:')
disp([molp.Aeq, molp.beq])
assert(isempty(molp.lb))
assert(isempty(molp.ub))

[lp, recover2] = minspanlp(molp.f, [], rmfield(molp, 'f'));

disp('=== standard lp ===')
disp('objectives:')
disp(lp.f)
disp('inequalities:')
disp([lp.Aineq, lp.bineq])
disp('equalities:')
disp([lp.Aeq, lp.beq])
assert(isempty(lp.lb))
assert(isempty(lp.ub))

[xy, fval, exitflag, output] = solver(lp);
if exitflag ~= 1
    disp(output)
    return
end

fprintf('----- %ux%u: %g -----\n', numbasestations, nummobiles, fval)
disp(recover1(recover2(xy)))

end
