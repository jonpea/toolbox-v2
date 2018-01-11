function [faceid, rayid, t, point, beta] = ...
    planarintersection( ...
    faceorigins, facenormals, offsettolocal, ...
    rayorigins, raydirections, tnear, tfar)

narginchk(7, 7)

% Preconditions
assert(ismatrix(faceorigins))
assert(ismatrix(facenormals))
assert(ndebug || isequal(size(faceorigins), size(facenormals)))
assert(isnumeric(offsettolocal))
assert(size(offsettolocal, 3) == size(faceorigins, 2) - 1)
assert(ismatrix(rayorigins))
assert(ismatrix(raydirections))
assert(size(rayorigins, 2) == size(faceorigins, 2))
assert(ndebug || isequal(size(rayorigins), size(raydirections)))
assert(isnumeric(tnear))
assert(isnumeric(tfar))

numrows = size(raydirections, 1);
tnear = columnvector(tnear, numrows);
tfar = columnvector(tfar, numrows);

timer = tic;
[t, select] = intersectmex( ...
    facenormals, faceorigins, ...
    raydirections, rayorigins, ...
    tnear, tfar);
elapsed = toc(timer); %#ok<NASGU>

% ---[Profiling Code Begins]--->>
% timer = tic;
% [t2, select2] = offsetwithimplicitsingletonexpansion();
% elapsed2 = toc(timer);
% timer = tic;
% [t3, select3] = offsetwithbsxfun();
% elapsed3 = toc(timer);
%     function result = isequaln(a, b, local)
%         % Relaxes the distinction between +Inf and -Inf
%         local.mask = ~isnan(a) & ~isinf(a);
%         result = all(a(local.mask) == b(local.mask));
%     end
% assert(isequaln(t, t2))
% assert(isequaln(t, t3))
% assert(isequaln(select, select2))
% assert(isequaln(select, select3))
% fprintf('----------------\n')
% fprintf('size = %d\n', numel(t))
% fprintf('elapsed  = %g\n', elapsed)
% fprintf('elapsed2 = %g\n', elapsed2)
% fprintf('elapsed3 = %g\n', elapsed3)
% fprintf('speed-up (2) = %g\n', elapsed2/elapsed)
% fprintf('speed-up (3) = %g\n', elapsed3/elapsed)
% <<---[Profiling Code Ends]---

    function [t, select] = offsetwithimplicitsingletonexpansion() %#ok<DEFNU>

        % Prepare for singleton expansion
        numslots = 3;
        sxshaperay = sx.shape(rayorigins, [1, numslots]);
        sxshapeface = sx.shape(facenormals, [2, numslots]);
        
        % Compute ray parameters of each candidate intersection point
        % TODO: Note that 
        %           "dot(facenormals, faceorigins)" 
        % can be replaced with "faceoffsets", although this may not
        % actually result in a significant reduction in work.
        numerators = sum( ...
            reshape(facenormals, sxshapeface) .* ( ...
            reshape(faceorigins, sxshapeface) - ...
            reshape(rayorigins, sxshaperay) ...
            ), ...
            numslots);
        
        denominators = sum( ...
            reshape(facenormals, sxshapeface) .* ...
            reshape(raydirections, sxshaperay), ...
            numslots);
                
        t = numerators ./ denominators;
        
        select = iswithin(t, tnear, tfar);        
    end

    function [t, select] = offsetwithbsxfun() %#ok<DEFNU>
        % Compute ray parameters of each candidate intersection point

        % Prepare for singleton expansion
        numslots = 3;
        sxshaperay = sx.shape(rayorigins, [1, numslots]);
        sxshapeface = sx.shape(facenormals, [2, numslots]);
        
        denominators = sum( ...
            bsxfun(@times, ...
            reshape(facenormals, sxshapeface), ...
            reshape(raydirections, sxshaperay) ...
            ), ...
            numslots);
        
        numerators = sum( ...
            bsxfun(@times, reshape(facenormals, sxshapeface), ...
            bsxfun(@minus, ...
                reshape(faceorigins, sxshapeface), ...
                reshape(rayorigins, sxshaperay))), ...
            numslots);

        t = bsxfun(@rdivide, numerators, denominators);
        
        select = iswithin(t, tnear, tfar);

    end

% Filter candidates according to ray parameter
% Notice the shapes in iswithin("MxN", "1xN", "1xN").
indices = find(select);
[rayid, faceid] = ind2sub(size(select), indices(:));
t = reshape(t(indices), [], 1); % "empty" is 0x1

assert(iscolumn(faceid))
assert(iscolumn(rayid))
assert(iscolumn(t))

% Cartesian coordinates of intersection points
point = rayorigins(rayid, :) + bsxfun(@times, raydirections(rayid, :), t(:));
%point2 = rayorigins(rayid, :) + raydirections(rayid, :) .* t(:);
%assert(isequal(point, point2))

% Filtering according to local "in-face" coordinates.
offset = point - faceorigins(faceid, :);
beta = sum(offsettolocal(faceid, :, :).*offset, 2);
beta = reshape(beta, [], size(offsettolocal, 3)); % since "Nx1x2" in 3D

selected = find(all(0.0 <= beta & beta <= 1.0, 2));
faceid = faceid(selected, :);
rayid = rayid(selected, :);
t = t(selected, :);
point = point(selected, :);

if nargout == 5
    beta = beta(selected, :);
end

end

% =========================================================================
% Implementation #2: Sequential
% This implementation is significantly slower than #1
% e.g. 21.2 seconds vs 1.6 seconds on a problem of reasonable size.
%{
numdimensions = size(faceorigins, 2); % before reshape operation, below
beta = zeros(numel(t), numdimensions - 1);
for i = 1 : size(offsettolocal, 3)
    beta(:, i) = dot(offsettolocal(faceid, :, i), offset, 2);
    selected = iswithin(beta(:, i), 0, 1);
    beta = beta(selected, :);
    faceid = faceid(selected, :);
    offset = offset(selected, :);
    rayid = rayid(selected, :);
    t = t(selected, :);
end
%}

% =========================================================================
function a = columnvector(a, numrows)
assert(ndebug || ismember(numel(a), [1, numrows]))
if isscalar(a)
    a = repmat(a, numrows, 1);
end
end
