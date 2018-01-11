function [te, tm] = yuennew

tiny = 1e-6;

fill = @(value, a) repmat(value, size(a, 1), 1);

generate = @(a) [ ...
    a(:, 1), fill(0, a), a(:, 2);
    a(:, 1), fill(360, a), a(:, 2);
    ];

te = generate([
    0 0.894627528630103
    5 0.895076836563656
    10 0.896500670706606
    15 0.899123496315072
    20 0.903306410426698
    25 0.909519642450060
    30 0.918285784010963
    35 0.930068705432572
    40 0.945062503746337
    45 0.962797323644490
    50 0.981415090508584
    55 0.996378024907815
    60 0.998315243312619
    65 0.969980011884529
    70 0.883882423155401
    75 0.707423592958525
    80 0.432126143120039
    85 0.136081435024490
    90 tiny
    ]);


tm = generate([
    0 0.894627528630103
    5 0.897378313847839
    10 0.905427926702601
    15 0.918129327455021
    20 0.934300457189518
    25 0.952163793225229
    30 0.969453618025107
    35 0.983831195959698
    40 0.993612037081721
    45 0.998518735483987
    50 0.999913764606590
    55 0.999999767441999
    60 0.999702956762363
    65 0.994811830750231
    70 0.969018314296423
    75 0.881934180066755
    80 0.659634589631595
    85 0.264140391540847
    90 tiny
    ]);