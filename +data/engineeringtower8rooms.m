function indices = engineeringtower8rooms

% Rooms are labelled anticlockwise, starting from origin
indices = {
    1  [1 7 8 20 21 2]; % bottom left (nearest origin)
    2  [7 30 31 21 20 8];
    3  [30 64 66 31];
    4  [64 69 70 56 55 66]; % bottom right
    5  [56 70 71 59];
    6  [59 71 72 62];
    7  [62 72 73 68 67 76]; % top right
    8  [46 67 68 47];
    9  [36 46 47 37];
    10 [26 36 37 16 15 27];
    11 [5 26 27 15 16 6]; % top left
    12 [4 12 14 5];
    13 [3 10 12 4];
    14 [2 74 10 3];
    15 [34 52 75 35]; % stairwell
    16 [24 75 53 25]; % toilet
    };

indices(:, 1) = [];
