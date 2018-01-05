function g = friisgain(distance, lambda, type)
%FRIISGAIN Friis formula for signal gain of free-space propagation.
% Further information on wikipedia.org:
%  https://en.wikipedia.org/wiki/Friis_transmission_equation

narginchk(2, 3)

if nargin < 3
    type = 'linear';
end

switch validatestring(lower(type), {'db', 'linear'}, mfilename, 'type', 3)
    
    case 'db'
        % This improves on the finite-precision accuracy of
        % the mathematically equivalent expression
        %  "todb(friisgrain(.., 'linear')) = 10*log10((..)^2)".
        g = 20*(log10(lambda) - log10(4*pi*distance));
        
    case 'linear'
        g = (lambda./(4*pi*distance)).^2;
        
end
