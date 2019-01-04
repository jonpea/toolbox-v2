function R = rotorsph(az, el)
import elmet.rotor
yaxis = [0; 1; 0];
zaxis = [0; 0; 1];
R = rotor3(yaxis, el)*rotor3(zaxis, az);
