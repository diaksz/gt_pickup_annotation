function center = GetCenterPos(pos)
center = zeros(1,2);
center(1) = mean(pos(:,1));%(max(pos(:,1))-min(pos(:,1)))/2+min(pos(:,1));
center(2) = mean(pos(:,2));%(max(pos(:,2))-min(pos(:,2)))/2+min(pos(:,2));
end