function fun = friisfunction(frequency, friis)
%FRIISFUNCTION Friis function for signal gain of free-space propagation.
% FUN = FRIISFUNCTION([FREQ(1), FREQ(2), ..., FREQ(N)]) returns a function
% handle such that
%            FUN(ID, DISTANCE)
%    returns FRIISDB(DISTANCE, LAMBDA(ID))
%      where LAMBDA(ID) is the wavelength SPEEDOFLIGHT/FREQ(ID)
%        and 1 <= ID <= N.
%
% See also FRIIS, FRIISDB.

narginchk(0, 2)

if nargin < 1 || isempty(frequency)
    frequency = centerfrequency;
end

if nargin < 2
    friis = @rayoptics.friisdb;
end

if isnumeric(frequency) && isscalar(frequency)
    frequency = @(~) frequency;
end

assert(datatypes.isfunction(frequency) || isvector(frequency))

    function result = evaluate(id, distance)
        %result = power.friisgain(distance, elfun.lightspeed./frequency(id), units);
        result = friis(distance, elfun.lightspeed./frequency(id));
    end

fun = @evaluate;

end

% -------------------------------------------------------------------------
function freq = centerfrequency
%CENTERFREQUENCY Center frequency for mobile radio communication.
freq = 2.45e9;
end
