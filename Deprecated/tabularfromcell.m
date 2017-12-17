function table = maketable(headings, rows)
table = tabularvertcat(table2struct( ...
    cell2table(rows, 'VariableNames', headings)));
end
