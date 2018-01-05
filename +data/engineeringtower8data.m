function [faces, vertices, gains] = engineeringtower8data

gain_glass = -3;
gain_concrete = -20;
gain_wall = -3;

header = { 'x1', 'y1', 'x2', 'y2', 'gain' }; %#ok<*NASGU>
data = num2cell([
    0,     0,    18.5, 0,    gain_glass;  % Exterior glass
    18.5,  0,    18.5, 18.5, gain_glass;
    18.5,  18.5, 0,    18.5, gain_glass;
    0,     18.5, 0,    0,    gain_glass;
    6,     6,    7.4,  6,    gain_concrete; % Concrete core
    8.4,   6,    9.2,  6,    gain_concrete;
    10.6,  6,    12.5, 6,    gain_concrete;
    12.5,  6,    12.5, 12.5, gain_concrete;
    12.5,  12.5, 9.4,  12.5, gain_concrete;
    8.3,   12.5, 6,    12.5, gain_concrete;
    6,     12.5, 6,    6,    gain_concrete;
    6,     8.2,  12.5, 8.2,  gain_concrete;
    6,     11.1, 11.1, 11.1, gain_concrete;
    8,     8.2,  8,    11.1, gain_concrete;
    4.4,   0,    4.4,  3,    gain_wall;
    4.4,   3,    6,    3,    gain_wall;
    6,     3,    6,    4.2,  gain_wall;
    7.4,   0,    7.4,  4.2,  gain_wall;
    7,     4.2,  10.6, 4.2,  gain_wall;
    14.9,  0,    14.9, 3.2,  gain_wall;
    11.6,  4.2,  14.9, 4.2,  gain_wall;
    14.3,  4.2,  14.3, 6.3,  gain_wall;
    14.3,  5.3,  18.5, 5.3,  gain_wall;
    14.3,  7.3,  14.3, 11.3, gain_wall;
    14.3,  9.2,  18.5, 9.2,  gain_wall;
    14.3,  12.2, 14.3, 13.2, gain_wall;
    14.3,  13.0, 18.5, 13.0, gain_wall;
    12.7,  14.3, 15.5, 14.3, gain_wall;
    15.5,  14.3, 15.5, 18.5, gain_wall;
    9.1,   14.3, 11.8, 14.3, gain_wall;
    11,    14.3, 11,   18.5, gain_wall;
    7.7,   14.3, 8.2,  14.3, gain_wall;
    8,     14.3, 8,    18.5, gain_wall;
    5.7,   14.3, 6.8,  14.3, gain_wall;
    6,     14.3, 6,    15.9, gain_wall;
    6,     15.9, 4.4,  15.9, gain_wall;
    4.4,   15.9, 4.4,  18.5, gain_wall;
    0,     14.3, 4.8,  14.3, gain_wall;
    4.4,   14.3, 4.4,  12.3, gain_wall;
    0,     11.1, 4.4,  11.1, gain_wall;
    0,     7.4,  4.4,  7.4,  gain_wall;
    4.4,   9.9,  4.4,  5.4,  gain_wall;
    0,     4.2,  4.7,  4.2,  gain_wall;
    ], 1);

[faces, vertices] = linestofacevertex(data{1 : 4});
gains = data{5};
