%function bestpairwisesirtest
clear, rng(0)
clc

runtest(3, 3)
 
runtest(4, 3)
runtest(4, 4)
% 
% runtest(5, 4)
% runtest(5, 5)

return

maxnumbasestations = 3;

for numbasestations = 2 : maxnumbasestations
    for nummobiles = 2 : numbasestations
        runtest(numbasestations, nummobiles)
    end
end

runtest(3, 3)

% -------------------------------------------------------------------------
function runtest(numBaseStations, numMobiles)

% Random gain data, each in the range [minGainDBW, maxGainDBW] in dBW.
minGainDBW = -50;
maxGainDBW = -1;
alpha = rand(numBaseStations, numMobiles);
pathGainDBW = (1 - alpha)*minGainDBW + alpha*maxGainDBW;
pathGain = specfun.fromdb(pathGainDBW);

% Solution via Kevin's iterative balancing routine
bestSIRDBW1 = powerbalance.CalculateBestSIR_pairwise(pathGain);

% Solution via Jon's rewrite of Kevin's routine
[bestSIRDBW2, txPowerOfMobile] = powerbalance.bestpairwisesir(pathGain);

% Verify that results are equal for this particular test instance
fprintf('========== %ux%u: %g == %g ==========\n', ...
    numBaseStations, numMobiles, bestSIRDBW1, bestSIRDBW2)
assert(isequaln(bestSIRDBW1, bestSIRDBW2))

% Solution via reformulation as generalized linear fractional program
[C, d, F, g] = SIRCoefficients(pathGain);
n = size(C, 2);

txPowerOfMobile0 = ones(size(txPowerOfMobile));
SIRAll = (C*txPowerOfMobile0(:))./(F*txPowerOfMobile0(:))';
SIRAllDBW = specfun.todb(SIRAll(:));
lower = min(SIRAllDBW);
upper = max(SIRAllDBW);
delta = 1e-3;

linprogOptions = optimoptions(@linprog, ...
    'Algorithm', 'dual-simplex', ...
    'ConstraintTolerance', 1e-9, ... %  scalar in [1e-9, 1e-3]; default is 1e-4
    'OptimalityTolerance', 1e-10, ...
    'Display', 'none');

[x, lower, upper] = optim.linfracprog( ...
    C, d, F, g, lower, upper, delta, ...
    [], ...          % "A"
    [], ...          % "b"
    ones(1, n), ...  % "Aeq": arbitrary normalization coefficients
    1.0, ...         % "beq": arbitrary normalization value
    zeros(n, 1), ... % "lb": non-negativity constraints
    ones(n, 1), ...  % "ub": upper bounds consistent with normalization
    linprogOptions);

fractions = (C*x(:))./(F*x(:));
maxfraction = max(fractions);

assert(lower < upper)
assert(upper - lower < delta)
assert(-eps(10*abs(lower) + 1) <= maxfraction - lower)
assert(-eps(10*abs(upper) + 1) <= upper - maxfraction)

% Scale for comparison, solved here by Nx1 least-squares fit
scale = x(:)\txPowerOfMobile(:);
computed = scale*x(:);

disp('Optimal Power:')
disp(struct2table(struct( ...
    'Actual', computed(:), ...
    'Expected', txPowerOfMobile(:))))

disp('SIR:')
disp(struct2table(struct( ...
    'Actual', powerbalance.uplinksir(pathGain, computed(:)')', ...
    'Expected', powerbalance.uplinksir(pathGain, txPowerOfMobile)')))

end

% -------------------------------------------------------------------------
function [C, d, F, g] = SIRCoefficients(pathGain)

narginchk(1, 1)
[numBaseStations, numMobiles] = size(pathGain);

% ===== Demonstration =====>>
txPowerOfMobile = rand(1, numMobiles);

% Total received power at each base station
% i.e. sum of powers received from each mobile
% [row for each base station]
baseStationRxPower = pathGain*txPowerOfMobile(:);

% Total interfering power at each base station where a
% particular mobile is desired and the others are interferers
% [row for each base station, column for each desired mobile]
desiredMobileRxPower1 = pathGain.*repmat(txPowerOfMobile, numBaseStations, 1);
desiredMobileRxPower2 = pathGain.*(ones(numBaseStations, 1)*txPowerOfMobile*eye(numMobiles));

C = diag(pathGain(:))*kron(eye(numMobiles), ones(numBaseStations, 1));
desiredMobileRxPower3 = zeros(numBaseStations, numMobiles);
desiredMobileRxPower3(:) = C*txPowerOfMobile(:);

assert(isequalfp(desiredMobileRxPower1, desiredMobileRxPower2))
assert(isequalfp(desiredMobileRxPower1, desiredMobileRxPower3))

baseStationInterferencePower1 = repmat(baseStationRxPower, 1, numMobiles) - desiredMobileRxPower1;
baseStationInterferencePower2 = baseStationRxPower*ones(1, numMobiles) - pathGain.*repmat(txPowerOfMobile, numBaseStations, 1);
baseStationInterferencePower3 = zeros(numBaseStations, numMobiles);
F = kron(ones(1, numMobiles)', pathGain) - C;
baseStationInterferencePower3(:) = F*txPowerOfMobile(:);

assert(isequalfp(baseStationInterferencePower1, baseStationInterferencePower2))
assert(isequalfp(baseStationInterferencePower1, baseStationInterferencePower3))
% <<===== Demonstration =====

C = diag(pathGain(:))*kron(eye(numMobiles), ones(numBaseStations, 1));
F = kron(ones(numMobiles, 1), pathGain) - C;
[d, g] = deal(zeros(size(C, 1), 1));

end

function tf = isequalfp(a, b)
%ISEQUALFP True if arguments are effectively equal (in finite precision).
normv = @(a) norm(a(:), inf);
tf = normv(a - b) < 1e-14*(normv(a) + normv(b) + 1);
end
