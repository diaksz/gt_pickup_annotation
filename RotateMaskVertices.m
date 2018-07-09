function rotVert = RotateMaskVertices(vert,rotationAngle,origin)

center = origin;
pos = vert;
poscenter = repmat(center,size(vert,1),1);
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
pos2 = (pos-poscenter) * rotationArray + poscenter;
rotVert = pos2;