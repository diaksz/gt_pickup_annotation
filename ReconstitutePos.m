
function [pos_slot,pos_section] = ReconstitutePos(S,M)
% slot
masktypeID = 1;
% rotate
rotationAngle = S.slot.rotation;
pos = M(masktypeID).pos_init;
center = GetCenterPos(pos);
poscenter = repmat(center,size(pos,1),1);
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
pos_slot = (pos-poscenter) * rotationArray + poscenter;
%     translate1 = pos2(1,:)-pos(1,:);

% translate
translationArray = S.slot.translation;% - translate1;
pos_slot(:,1) = pos_slot(:,1)+translationArray(1);
pos_slot(:,2) = pos_slot(:,2)+translationArray(2);

% section
masktypeID = 2;
% rotate
rotationAngle = S.section.rotation;
pos = M(masktypeID).pos_init;
center = GetCenterPos(pos);
poscenter = repmat(center,size(pos,1),1);
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
pos_section = (pos-poscenter) * rotationArray + poscenter;
%     translate1 = pos2(1,:)-pos(1,:);

% translate
translationArray = S.section.translation;% - translate1;
pos_section(:,1) = pos_section(:,1)+translationArray(1);
pos_section(:,2) = pos_section(:,2)+translationArray(2);

end