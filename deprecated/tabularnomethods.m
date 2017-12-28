function t = tabularnomethods(t)
tokeep = cell2mat(struct2cell( ...
    structfun(@isfunction, t, 'UniformOutput', false)));
names = fieldnames(t);
t = rmfield(t, names(tokeep));
