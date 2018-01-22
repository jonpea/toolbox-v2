function [sirdbformobile, basestationformobile, basestationrxpower] = ...
    uplinksir(pathgain, txpowerofmobile, glfp)

narginchk(2, 3)
if nargin < 3 || isempty(glfp)
    glfp = false;
end

assert(isrow(txpowerofmobile))
assert(size(pathgain, 2) == numel(txpowerofmobile))

% Total received power at each base station
% i.e. sum of powers received from each mobile
% [row for each base station]
basestationrxpower = pathgain * txpowerofmobile(:);

% Total interfering power at each base station where a
% particular mobile is desired and the others are interferers
% [row for each base station, column for each desired mobile]
[numbasestations, nummobiles] = size(pathgain);
desmobRXpow = pathgain .* repmat(txpowerofmobile, numbasestations, 1);
BSintfpow = repmat(basestationrxpower, 1, nummobiles) - desmobRXpow;

% SIR (in dB) at each base station for each desired mobile
% [row for each base station, column for each (desired) mobile]
sirdb = specfun.todb(desmobRXpow ./ BSintfpow);

% For each mobile (i.e. down each column), determine BS with max SIR
% Each output has [column for each mobile]
[sirdbformobile, basestationformobile] = max(sirdb, [], 1);

% -------------------------------------------------------------------------
% Formulation as a generalized linear-fractional program
% See Boyd & Vandenberghe (2004), page 152, section 4.3.2
% The benefit is that additional linear (in/equality) constraints
% would be easily incorporated by standard linear programming routines.
compare = @(actual, expected) assert(isequalfp(actual, expected, 1e-12));

E = diag(pathgain(:))*kron(eye(nummobiles), ones(numbasestations, 1));
F = kron(ones(nummobiles, 1), pathgain) - E;
x = txpowerofmobile;

desmobRXpow_vec = E*x(:);
BSintfpow_vec = F*x(:);

unvec = @(vec) reshape(vec, size(pathgain));
compare(unvec(desmobRXpow_vec), desmobRXpow)
compare(unvec(BSintfpow_vec), BSintfpow)

sirdb_vec1 = specfun.todb(desmobRXpow_vec) - specfun.todb(BSintfpow_vec);
sirdb_vec2 = specfun.todb(desmobRXpow_vec./BSintfpow_vec);
compare(unvec(sirdb_vec1), sirdb)
compare(unvec(sirdb_vec2), sirdb)

if glfp
    blank = zeros(size(E, 1), 1);
    sirdbformobile = struct( ...
        'c', E, ...
        'd', F, ...
        'c0', blank, ...
        'd0', blank, ...
        'm', numbasestations, ...
        'n', nummobiles);
end

return

% c1 = E;
% c2 = F;
% [numobjectives, numvariables] = size(c1);
% [d1, d2] = deal(zeros(numobjectives, 1));
% glfp = struct; % Beware: This name previously bound to logical
% glfp.Aineq = [];
% glfp.bineq = [];
% glfp.Aeq = [];
% glfp.beq = [];
% glfp.lb = zeros(numvariables, 1);
% glfp.ub = ones(numvariables, 1);
% 
% disp('=== original gflp objectives ===')
% disp('numerator:')
% disp([c1, d1])
% disp('denominator:')
% disp([c2, d2])
% 
% classname = class(c1);
% nearinf = realmax(classname);
% zero = zeros(classname);
% one = ones(classname);
% 
% % Homogenize the objective denominator of the linear-fractional program
% % ---------------------------------------------------------------------
% % Containers for new constraint relations
% Aeq = {}; Aineq = {};
% beq = {}; bineq = {};
%     function posteq(A, b)
%         % Post equalities "A*x == b"
%         [Aeq, beq] = post(Aeq, beq, A, b);
%     end
%     function postineq(A, b)
%         % Post inequalities "A*x <= b"
%         [Aineq, bineq] = post(Aineq, bineq, A, b);
%     end
%     function [AA, bb] = post(AA, bb, A, b)
%         % Post homogenized affine-linear constraints
%         assert(size(A, 1) == numel(b))
%         AA{end + 1} = afftohom(A, b(:));
%         bb{end + 1} = zeros(numel(b), 1, 'like', b);
%     end
% 
% % Homogenize any existing constraints
% I = eye(numvariables, 'like', glfp.Aineq); % preserves storage format
% if ~isempty(glfp.lb)
%     postineq(-I, -glfp.lb)
% end
% if ~isempty(glfp.ub)
%     postineq(I, glfp.ub)
% end
% if ~isempty(glfp.Aineq)
%     postineq(glfp.Aineq, glfp.bineq)
% end
% if ~isempty(glfp.Aeq)
%     posteq(glfp.Aeq, glfp.beq)
% end
% 
% % Pack posted constraints into new representation
% combine = @(cells, varargin) vertcat(cells{:}, varargin{:});
% molp.f = [c1, d1];
% molp.Aeq = combine(Aeq, [c2, d2]);
% molp.beq = combine(beq, ones(numobjectives, 1));
% molp.Aineq = combine(Aineq, [
%     zeros(1, numvariables), -one;
%     ]);
% molp.bineq = combine(bineq, [ ...
%     zero;
%     ]);
% molp.lb = []; % no lower bounds
% molp.ub = []; % no upper bounds
% 
% disp('=== homogenized gflp ===')
% disp('objectives:')
% disp(molp.f)
% disp('inequalities:')
% disp([molp.Aineq, molp.bineq])
% disp('equalities:')
% disp([molp.Aeq, molp.beq])
% assert(isempty(molp.lb))
% assert(isempty(molp.ub))
% 
% % Auxiliaries representing "maximum over base-stations for each mobile"
% % ---------------------------------------------------------------------
% lp1.Aineq = [
%     padcolumns(molp.Aineq, nummobiles);
%     molp.f, -columnselector(numbasestations, nummobiles);
%     ];
% lp1.bineq = [
%     molp.bineq;
%     repmat(zero, numbasestations*nummobiles, 1);
%     ];
% lp1.Aeq = [molp.Aeq, repmat(zero, numbasestations*nummobiles, 2)];
% lp1.beq = molp.beq;
% lp1.lb = [];
% lp1.ub = [];
% 
% disp('=== lp1 ===')
% disp('inequalities:')
% disp([lp1.Aineq, lp1.bineq])
% disp('equalities:')
% disp([lp1.Aeq, lp1.beq])
% assert(isempty(lp1.lb))
% assert(isempty(lp1.ub))
% 
% % Auxiliaries representing "maximum over base-stations for each mobile"
% % ---------------------------------------------------------------------
% r = size(molp.Aineq, 2);
% I = eye(nummobiles, 'like', lp1.Aineq);
% lp2.Aineq = [
%     padcolumns(lp1.Aineq, 2);
%     repmat(zero, nummobiles, r), -I, repmat([+one, zero], nummobiles, 1);
%     repmat(zero, nummobiles, r), +I, repmat([zero, -one], nummobiles, 1);
%     repmat(zero, 1, r + nummobiles), one, -one;
%     ];
% lp2.bineq = [
%     lp1.bineq;
%     repmat(zero, nummobiles, 1);
%     repmat(zero, nummobiles, 1);
%     zero;
%     ];
% lp2.Aeq = padcolumns(lp1.Aeq, 2);
% lp2.beq = lp1.beq;
% n = ...
%     nummobiles ... % transmission power for each mobile
%     + 1 ...        % auxiliary for homogenization of fractional program
%     + nummobiles;  % auxiliaries for maximum over base-stations for each mobile
% lp2.f = [repmat(zero, 1, n), -one, +one];
% lp2.lb = [];
% lp2.ub = [];
% 
% disp('=== lp2 ===')
% disp('objectives:')
% disp(lp2.f)
% disp('inequalities:')
% disp([lp2.Aineq, lp2.bineq])
% disp('equalities:')
% disp([lp2.Aeq, lp2.beq])
% disp('bounds:')
% disp(lp2.lb)
% disp(lp2.ub)
% 
% solver = @linprog;
% lp2.solver = char(solver);
% lp2.options = optimoptions(solver, ...
%     'Display', 'iter', ...
%     'Diagnostics', 'on');
% 
% [xy, fval, exitflag, output] = solver(lp2);
% if exitflag ~= 1
%     disp(output)
%     return
% end

end
