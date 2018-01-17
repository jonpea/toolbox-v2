function alpha = elinc(beta)
%ELINC Conversion between elevation and inclination.
%   EL = ELINC(INC) converts inclination INC to elevation EL.
%
%   INC = ELINC(EL) converts elevation EL to inclination INC.
%
%   ELINC is involutive i.e. ELINC(ELINC(X)) == X.
%
%   See also SPHI.

alpha = pi/2 - beta;
