function [best_SIR_dB, txpowerofmobile] = bestpairwisesir(pathgain)
%BESTPAIRWISESIR Best achievable SIR.
% BESTPAIRWISESIR(PATHGAINS) is the best SIR achievable for a given
% if PATHGAIN(BS,MOB) is the power multiplier (gain) between
% base station BS and mobile MOB.
% PATHGAINS should have at last as many rows as columns
% i.e. there must be at least as many base stations as mobiles.

assert(ismatrix(pathgain))
assert(~isempty(pathgain))
assert(size(pathgain, 2) >= 2)

% Transmission power for each mobile (uplink power), initially all one
% [column for each mobile]
nummobiles = size(pathgain, 2);
txpowerofmobile = ones(1, nummobiles);

if nummobiles == 2
    % Special shortcut: With just one interfering mobile, use mean of SIRs
    best_SIR_dB = mean(uplinksir(pathgain, txpowerofmobile));
    return
end

% Iteratively adjust power of each mobile to make best SIR equal to target
for i = 1 : 200
    
    [maxsirdbformobile, basestationconnectedto, basestationrxpower] = uplinksir(pathgain, txpowerofmobile);
    
    % Index of mobile with minimum (resp. maximum) SIR;
    % choose the first if these are not unique.
    [sirmin, mobmin] = min(maxsirdbformobile);
    [sirmax, mobmax] = max(maxsirdbformobile);
    
    if sirmax - sirmin <= bestpairwisesirtol % 0.05
        break % stop when all mobiles have (approx.) same SIR
    end
    
    % Available values:
    %    txpowerofmobile: the transmitter power of each mobile
    %            mobmax: number of mobile with current maximum SIR at its BS,
    %            mobmin: number of mobile with current minimum SIR at its BS,
    % basestationrxpower: total power received at each BS (desired & interfering)
    %      pathgain: channel (power) gains between BSs and mobiles
    % basestationconnectedto(mobmax)
    % basestationconnectedto(mobmin)
        
    gainfor = @(mob1, mob2) ...
        pathgain(basestationconnectedto(mob1), mob2);
    gaa = gainfor(mobmax, mobmax);
    gbb = gainfor(mobmin, mobmin);
    gab = gainfor(mobmax, mobmin);
    gba = gainfor(mobmin, mobmax);
    gains = [
        gainfor(mobmin, mobmin), gainfor(mobmin, mobmax);
        gainfor(mobmax, mobmin), gainfor(mobmax, mobmax);
        ];
    txpowers = txpowerofmobile([mobmin, mobmax]);
    basestations = basestationconnectedto([mobmin, mobmax]);
    rxpowers = basestationrxpower(basestations);
    interferencepower = rxpowers(:) - gains*txpowers(:);
    
    % Interference power at basestationconnectedto(mobmax) and basestationconnectedto(mobmin)
    % from all mobiles other than mobmax and mobmin
    Imobmax = basestationrxpower(basestationconnectedto(mobmax)) - gaa*txpowerofmobile(mobmax) - gab*txpowerofmobile(mobmin);
    Imobmin = basestationrxpower(basestationconnectedto(mobmin)) - gba*txpowerofmobile(mobmax) - gbb*txpowerofmobile(mobmin);
    assert(isequalfp(interferencepower, [Imobmin; Imobmax], 1e-12))
    
    % Target SIR (in dB) for two mobiles (mobmax and mobmin) is midway
    % between their two SIR values, so adjust the gain of mobmax down by
    % gain_change_dB and adjust the gain of mobmin up by gain_change_dB
    target_SIR_dB = 0.5*(sirmin + sirmax);
    
    gam = specfun.fromdb(target_SIR_dB);
    
    KK = (gaa*gbb)/gam - gam*gab*gba;
    
    % Adjust transmission power of mobmin & mobmax
    txpowerofmobile(mobmax) = (Imobmax*gbb + gam*Imobmin*gab)/KK;
    txpowerofmobile(mobmin) = (Imobmin*gaa + gam*Imobmax*gba)/KK;
    temp = (Imobmax*gbb + gam*Imobmin*gab)/KK;
    
end

% Scalar value representing the SIR achievable after several iterations
% the best SIR for each mobile will equalise with that for each other
% mobile. This SIR will be the best achievable given the gain matrix and
% assuming the best choice of BS connections and the use of joint power
% control.
% Note that without power control the best SIRs from the first iteration
% will be the SIR values achieved.
best_SIR_dB = min(maxsirdbformobile);
assert(best_SIR_dB == sirmin)

% BS_SIR_dB    % for displaying during testing
% best_SIR_dB  % for displaying during testing

% -------------------------------------------------------------------------


