function evaluator = friisfunction(frequency, fun)
%FRIISFUNCTION Friis function for signal gain of free-space propagation.
% FUN = FRIISFUNCTION([FREQ(1), FREQ(2), ..., FREQ(N)]) returns a function
% handle such that
%            FUN(ID, DISTANCE)
%    returns FRIISGAIN(DISTANCE, LAMBDA(ID), 'db')
%      where LAMBDA(ID) is the wavelength SPEEDOFLIGHT/FREQ(ID)
%        and 1 <= ID <= N.
%
% FRIISFUNCTION([...], UNITS) specifies the units of power
%      where UNITS is 'db' or 'linear'.
%
% See also FRIISGAIN.

narginchk(0, 2)

if nargin < 1 || isempty(frequency)
    frequency = centerfrequency;
end

if nargin < 2
    %units = 'db';
    fun = @rayoptics.friisdb;
end

if isnumeric(frequency) && isscalar(frequency)
    frequency = @(~) frequency;
end

assert(datatypes.isfunction(frequency) || isvector(frequency))

    function result = evaluate(id, distance)
        %result = power.friisgain(distance, elfun.lightspeed./frequency(id), units);
        result = fun(distance, elfun.lightspeed./frequency(id));
    end

evaluator = @evaluate;

end