function [S,tf] = ScanText_GTA(secID,outputPath,slot_mask_file,section_mask_file)
tf = 0;
% scan in numbers
f = fullfile(outputPath,[num2str(secID),'.txt']);
% f = fullfile(outputPath,[num2str(secID,'%04d'),'.txt']);

% store info in struct
S = [];
S.secID = secID;

%%%%%%%%%%%%% hack %%%%%%%%%%%%%
if exist('slot_mask_file','var')
    S.slot_mask_file = slot_mask_file; % hack
end
if exist('section_mask_file','var')
    S.section_mask_file = section_mask_file; % hack
end

if exist(f, 'file') == 2
    try
        X = dlmread(f,' ',5,0);

        S.slot.translation = [X(1,1),X(1,2)];
        S.slot.rotation = X(1,3);
        S.section.translation = [X(2,1),X(2,2)];
        S.section.rotation = X(2,3);
        S.is_problematic = X(3,1);
        S.is_verified = X(3,2);
        
        tf = 1;
        
    catch
        S.slot.translation = [0,0];
        S.slot.rotation = 0;
        S.section.translation = [0,0];
        S.section.rotation = 0;
        S.is_problematic = 0;
        S.is_verified = 0;
    end
    
else % txt file doesn't exist
    S.slot.translation = [0,0];
    S.slot.rotation = 0;
    S.section.translation = [0,0];
    S.section.rotation = 0;
    S.is_problematic = 0;
    S.is_verified = 0;
end

end