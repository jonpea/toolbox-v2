function height = pmclevelheight(level)

librarylevel = 5;
studheight = 3000; % [mm]
receiverheight = 2000; % [mm]
height = (level - librarylevel)*studheight + receiverheight;

height = height/1000; % convert [mm] to [m]