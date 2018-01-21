function mds = minimumdiscernablesignal(options)
% MINIMUMDISCERNABLESIGNAL Minimum discernable signal in dBw

if nargin == 1
    assert(isstruct(options))
    fieldname = 'MinimumDiscernableSignal';
    if isfield(options, fieldname)
        mds = options.(fieldname);
        return
    end
end

mds = -100; % [dBW]
