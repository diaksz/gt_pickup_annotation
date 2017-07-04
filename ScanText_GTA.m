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
        f = fullfile(outputPath,[num2str(secID),'.txt']);
        
        fid = fopen(f, 'rt');
        s = textscan(fid, '%s', 'delimiter', '\n');
        
        slot_start_line = find(strcmp(s{1}, 'SLOT'), 1, 'first');
        slot_end_line = find(strcmp(s{1}, 'TOLS'), 1, 'first');
        S.slot.vertices = dlmread(f,'',[slot_start_line 0 slot_end_line-2 1]);
        
        section_start_line = find(strcmp(s{1}, 'SECTION'), 1, 'first');
        section_end_line = find(strcmp(s{1}, 'NOITCES'), 1, 'first');
        S.section.vertices = dlmread(f,'',[section_start_line 0 section_end_line-2 1]);

        slot_COM_line = find(strcmp(s{1}, 'SLOTCOM(x,y,theta):'), 1, 'first');
        X = dlmread(f,' ',[slot_COM_line 0 slot_COM_line 2]);    
        S.slot.translation = [X(1,1),X(1,2)];
        S.slot.rotation = X(1,3);
        
        section_COM_line = find(strcmp(s{1}, 'SECTIONCOM(x,y,theta):'), 1, 'first');
        X = dlmread(f,' ',[section_COM_line 0 section_COM_line 2]);    
        S.section.translation = [X(1,1),X(1,2)];
        S.section.rotation = X(1,3);
        
        
        flags_line = find(strcmp(s{1}, 'FLAGS'), 1, 'first');
        X = dlmread(f,' ',[flags_line+1 0 flags_line+1 1]);
        S.is_problematic = X(1,1);
        S.is_verified = X(1,2);
        
        tf = 1;
        
    catch
        print(['Error Reading Annotation File' num2str(secID)]);
        S.slot.vertices = [];
        S.slot.translation = [0,0];
        S.slot.rotation = 0;
        S.section.vertices = [];
        S.section.translation = [0,0];
        S.section.rotation = 0;
        S.is_problematic = 0;
        S.is_verified = 0;
    end
    
else % txt file doesn't exist
    S.slot.vertices = [];
    S.slot.translation = [0,0];
    S.slot.rotation = 0;
    S.section.vertices = [];
    S.section.translation = [0,0];
    S.section.rotation = 0;
    S.is_problematic = 0;
    S.is_verified = 0;
end

end