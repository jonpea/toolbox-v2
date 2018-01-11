function [ best_SIR_dB ] = CalculateBestSIR_pairwise( pg_pow )
%CalculateBestSIR Calculates the best SIR (in dB) achievable for a given
%set of mobiles and a set of base stations. Note that there must be at
%least as many base stations as mobiles
%   pgpow is a matrix of path gains expressed as power multipliers, with
%   a row for each BS and a column for each mobile.
[n_BS, n_mob] = size(pg_pow); % find number of base stations and number of mobiles


% Create mobile power vector (1 by n_mob)
mobTXpow = ones(1,n_mob); % set all mobile powers to 1 initially

% Create mob_BS_connect vector i.e. which BS does each mobile connect to
% [maxgain,BScon]= max(pg_pow); % use max function to find BS with max gain for each mobile
% mob_BS_connect = BScon; % intially connect each mobile to BS giving least pathloss


%Now find total received power at each BS i.e. sum of powers received from
%each mobile
BSRXpow = pg_pow * (mobTXpow'); % a column vector with each row the total received power at that BS

% Now find the total interfering power at each BS assuming a particular
% mobile is desired and the others are interferers
% BSintfpow will be a matrix with rows for each BS and columns for each
% desired mobile
desmobRXpow = pg_pow .* repmat(mobTXpow,n_BS,1);
BSintfpow = repmat(BSRXpow,1,n_mob) - desmobRXpow;

% SIR can now be found at each BS for each desired mobile
BS_SIR = desmobRXpow./BSintfpow; % BS_SIR will be a matrix with rows for each BS and columns for each
% desired mobile
% BS_SIR = min(BS_SIR,1e+14); % to avoid cases where BSintfpow = 0 and therefore BS_SIR = Inf
% pg_pow
BS_SIR_dB = 10*log10(BS_SIR); % SIR expressed in dB

[maxSIR_dB,BScon]= max(BS_SIR_dB); % use max function to find BS with max SIR for each mobile
% mob_BS_connect = BScon; % connect each mobile to BS giving highest SIR
% BScon

mob_max = find((max(maxSIR_dB)==maxSIR_dB),1); % Find number (index) of mobile with maximum SIR (just chose first if more than one share maximum value)
mob_min = find((min(maxSIR_dB)==maxSIR_dB),1); % Find number (index) of mobile with minimum SIR (just chose first if more than one share minimum value)

if n_mob == 2
    % best_SIR_dB = 0.5*10*log10(prod(maxSIR)); % special case for just two mobiles
    best_SIR_dB = 0.5*(sum(maxSIR_dB)); % special case for just two mobiles
    % use mean of SIRs in dB
    
else
    % *********************************************************************
    
    % Now iterate and adjust power of each mobile to make best SIR equal to
    % target
    i = 0;
    
    tol = bestpairwisesirtol;
    
    while and(((maxSIR_dB(mob_max) - maxSIR_dB(mob_min)) > tol) , (i < 200)) % end loop when all mobile have the same SIR or when counter reaches 200
        
        % On entering this loop, available are:
        % mobTXpow  the transmitter power of each mobile
        % mob_max  number of mobile with current maximum SIR at its BS,
        % BScon(mob_max)
        % mob_min  number of mobile with current minimum SIR at its BS,
        % BScon(mob_min)
        % BSRXpow   The total power received at each BS (desired and interfering
        % pg_pow the matrix of channel (power) gains between BSs and mobiles
        %
        gaa = pg_pow(BScon(mob_max),mob_max);
        gbb = pg_pow(BScon(mob_min),mob_min);
        gab = pg_pow(BScon(mob_max),mob_min);
        gba = pg_pow(BScon(mob_min),mob_max);
        
        % Need to calculate the interference power at BScon(mob_max) and
        % BScon(mob_min)from all mobiles other than mob_max and mob_min
        % Call this Imob_max and Imob_min
        %
        Imob_max = BSRXpow(BScon(mob_max)) - gaa*mobTXpow(mob_max) - gab*mobTXpow(mob_min);
        Imob_min = BSRXpow(BScon(mob_min)) - gba*mobTXpow(mob_max) - gbb*mobTXpow(mob_min);
        %
        
        
        target_SIR_dB = (maxSIR_dB(mob_max)+ maxSIR_dB(mob_min))/2; % target SIR (in dB) for two mobiles (mob_max and mob_min)
        % is midway between their two SIR values, so adjust the gain of
        % mob_max down by gain_change_dB and adjust the gain of mob_min up
        % by gain_change_dB.
        
        gam = 10^(target_SIR_dB/10);
        
        KK = (gaa*gbb)/gam - gam*gab*gba;
        
        mobTXpow(mob_max) = (Imob_max*gbb + gam*Imob_min*gab)/KK; % adjust Tx power of mob_max
        mobTXpow(mob_min) = (Imob_min*gaa + gam*Imob_max*gba)/KK; % adjust Tx power of mob_min
        
        
        
        BSRXpow = pg_pow * (mobTXpow'); % a column vector with each row the total received power at that BS
        
        % Now find the total interfering power at each BS assuming a particular
        % mobile is desired and the others are interferers
        % BSintfpow will be a matrix with rows for each BS and columns for each
        % desired mobile
        desmobRXpow = pg_pow .* repmat(mobTXpow,n_BS,1);
        BSintfpow = repmat(BSRXpow,1,n_mob) - desmobRXpow;
        
        % SIR can now be found at each BS for each desired mobile
        BS_SIR = desmobRXpow./BSintfpow; % BS_SIR will be a matrix with rows for each BS and columns for each
        % desired mobile
        % BS_SIR = min(BS_SIR,1e+20); % to avoid cases where BSintfpow = 0 and therefore BS_SIR = Inf
        
        BS_SIR_dB = 10*log10(BS_SIR); % SIR expressed in dB
        
        [maxSIR_dB,BScon]= max(BS_SIR_dB); % use max function to find BS with max SIR for each mobile
        % mob_BS_connect = BScon; % connect each mobile to BS giving highest SIR
        % BScon
        
        mob_max = find((max(maxSIR_dB)==maxSIR_dB),1); % Find number (index) of mobile with maximum SIR (just chose first if more than one share maximum value)
        mob_min = find((min(maxSIR_dB)==maxSIR_dB),1); % Find number (index) of mobile with minimum SIR (just chose first if more than one share minimum value)
        
        i = i+1;  % increment the counter
        
    end
    
    best_SIR_dB = min(maxSIR_dB); % a scalar value representing the SIR achievable
    % after several iterations the best SIR for each mobile will equalise with
    % that for each other mobile. This SIR will be the best achievable given
    % the gain matrix and assuming the best choice of BS connections and the
    % use of joint power control.
    % Note that without power control the best SIRs from the first iteration
    % will be the SIR values achieved.
    
    
end

% BS_SIR_dB    % for displaying during testing
% best_SIR_dB  % for displaying during testing
end
