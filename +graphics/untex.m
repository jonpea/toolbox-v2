function formula = untex(formula, varargin)
%UNTEX MATLAB-compatible version of LaTeX formula.
%   UNTEX(FORMULA) for character array FORMULA containing a LaTeX formula
%   returns a modified version suitable for use in FPRINTF and TEXT etc.
%
%   UNTEX(FORMAT,ARG1,ARG2,...) is equivalent to
%     SPRINTF(UNTEX(FORMAT),ARG1,ARG2,...).
%
%   Examples:
%   >> untex('$\mathbf{e}_%u$')
%   ans =
%       '$$\\mathbf{e}_%u$$'
%
%   >> untex('$\mathbf{e}_%u$', 3)
%   ans =
%       '$$\mathbf{e}_3$$' 
%
%   See also FPRINTF, SPRINTF, TEXT, TEX.

narginchk(1, nargin)

formula = replace(formula, {'\', '$'}, {'\\', '$$'});

if nargin == 1
    % NB: This guard is not in the interest of efficiency.
    % Rather, it is because SPRINTF is only appropriate if *all*
    % substitution values are both known and provided at the time of
    % calling this function: Any unmatched format specifiers in the string
    % will otherwise not be properly handled by SPRINTF.
    return
end

formula = sprintf(formula, varargin{:});
