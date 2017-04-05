% problem: txt file name does not match image name exactly: leading 0s

% open file
f = fullfile(outputPath,[num2str(secID),'.txt']);

%% can't save into section 0 (indexing fail)