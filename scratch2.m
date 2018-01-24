clear

period = 3;
wrap1 = @(t) specfun.wrapquadrant(t, period);
wrap2 = @(t) specfun.tri(t, period/2)*period/4;

t = linspace(-10, 10, 10000);

figure(1), clf('reset'), hold on
subplot(2, 1, 1)
plot(t, wrap1(t), '.', t, wrap2(t), 'o')
subplot(2, 1, 2)
semilogy(t, abs(wrap1(t) - wrap2(t)))
%assert(isequal(wrap1(t), wrap2(t)))


