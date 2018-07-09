
%% ATK 170703
tapedir = -1; % negative is feed reel starts from high section numbers
startSectionID = 330;
endSectionID = 450;
skipList = [498,494,445,416,400,349,332,322,321,316,315,314,309,304,303,301,299,294,269,248,241,240,239,238,237,236,235,233,232];
write_json = 1;
plot_imgs = 1;
sectionList = startSectionID:endSectionID;
sectionList = setdiff(sectionList,skipList,'stable');
%% Set paths and load mask and image
% master path
if ispc
    masterPath = '/home/aaron/SHH2';
    %masterPath = '/home/lab/170601_P26_Emx_SHH_wt2_r130';
elseif isunix
    masterPath = '/home/aaron/SHH2';
    %masterPath = '/home/lab/170601_P26_Emx_SHH_wt2_r130';
else
    disp('OS error - not Win or Unix');
end
queue_output = [masterPath '/queues/' date '_' num2str(startSectionID) '-' num2str(endSectionID) '.json'];

% saved mask templates for slot and section, respectively, in txt
slot_mask_file = [masterPath '/masks/' 'slotMask.txt'];
section_mask_file = [masterPath '/masks/' 'section_mask_features_448_180628.txt'];
%section_mask_file = [masterPath '/masks/' 'section_3_mask.txt'];
focus_mask_file = [masterPath '/masks/' 'focus_mask.txt'];

% output of annotation, in txt
outputPath = [masterPath '/annotations']; % saves annotated relative positions to txt, for each individual section
if exist(outputPath,'dir')~=7
    mkdir(outputPath);
end
%setappdata(hfig,'outputPath',outputPath);

% image folder
imPath = [masterPath '/img_links']; % contains images of individual sections
%ParseImageDir(hfig,imPath);

% start writing json file (will continue in for loop over sections)
if write_json == 1
    fileID = fopen(queue_output,'wt');
    fprintf(fileID,'{');
end

%% ATK 180625 - Intermediate code for ROI masks. Should be integrated into GUI soon.

section_mask_ref_file = [masterPath '/masks/' 'section_mask_ref_448_180628.txt'];
ROI_mask_file = [masterPath '/masks/' 'ROI_mask_448_180628.txt'];

% Get orig section mask vertices (masks format)
fid3 = fopen(ROI_mask_file);
section_mask_orig = dlmread(section_mask_file,' ',1,0);
section_mask_xy = [mean(section_mask_orig(:,1)),mean(section_mask_orig(:,2))];
section_mask_angle_ref = section_mask_orig(3,:)-section_mask_orig(2,:);
section_mask_angle = atan(section_mask_angle_ref(2)/section_mask_angle_ref(1));
fclose(fid3);

% Get model section mask COM and rotation (section annotation format)
fid = fopen(section_mask_ref_file, 'rt');
s = textscan(fid, '%s', 'delimiter', '\n');
idx3 = find(strcmp(s{1}, 'SECTION'), 1, 'first');
idx4 = find(strcmp(s{1}, 'NOITCES'), 1, 'first');
section_ref = dlmread(section_mask_ref_file,'',[idx3 0 idx4-2 1]);
idx = find(strcmp(s{1},'SECTIONCOM(x,y,theta):'), 1, 'first');
section_xyTH = dlmread(section_mask_ref_file,'',[idx 0 idx 2]);
%section_xy = section_xyTH(1:2);
section_xy = [mean(section_ref(:,1)),mean(section_ref(:,2))];
%section_angle = section_xyTH(3); %angles are not accurate!
section_angle_ref = section_ref(3,:)-section_ref(2,:);
section_angle = atan(section_angle_ref(2)/section_angle_ref(1));
% ATH 180625 but this needs to be relative

fclose(fid);

delta_xy = section_xy - section_mask_xy;
delta_angle = section_angle - section_mask_angle;

% Get ROI mask vertices (masks format)
fid2 = fopen(ROI_mask_file, 'rt');
ROI_ref = dlmread(ROI_mask_file,' ',1,0);
fclose(fid2);

% Rotate ROI back to ref mask
section_mask_calc = RotateMaskVertices(section_ref,delta_angle,section_xy)-delta_xy;%RotateMaskVertices(section_ref,-section_angle,section_xy)+delta_xy;
test = section_mask_calc - section_mask_orig;

% ROIvert_mask is the ROI in the original mask reference frame
ROIvert_mask = RotateMaskVertices(ROI_ref,-section_angle,section_xy)-delta_xy;

%% Set up figure (for annotation images)
if plot_imgs == 1
    scrn = get(0,'Screensize');
    hfig1 = figure('Position',[scrn(3)*0 scrn(4)*0 scrn(3)*1 scrn(4)*1],...% [50 100 1700 900]
        'Name','writeTestJson','ToolBar', 'none'); % 'MenuBar', 'none'
    hold off; axis off
    
    % init GUI drawing axes
    ax_pos = [0.1, 0.1, 0.8, 0.7];
    % setappdata(hfig,'ax_pos',ax_pos);
    figure(hfig1);
    h_ax = axes('Position',ax_pos);
    axis image
end
%% Parse annotation text files
% check for validation
problematic = zeros(length(sectionList),1);
verified = zeros(length(sectionList),1);
for i = 1:length(sectionList)
    f = fullfile(outputPath,[num2str(sectionList(i)),'.txt']);
    fid = fopen(f, 'rt');
    s = textscan(fid, '%s', 'delimiter', '\n');
    
    idx5 = find(strcmp(s{1}, 'FLAGS'), 1, 'first');
    flags = dlmread(f,'',[idx5+1 0 idx5+1 1]);
    problematic(i) = flags(1);
    verified(i) = flags(2);
    fclose(fid);
end
problems = sectionList(find(problematic==1));
unverified = sectionList(find(verified==0));

disp(['Problem sections: ' num2str(problems)]);
if ~isempty(unverified) > 0
    error(['Unverified sections: ' num2str(unverified)]);
end
%%
tf = [];
% start writing json file (will continue in for loop over sections)
if write_json == 1
    fileID = fopen(queue_output,'wt');
    fprintf(fileID,'{');
end

for i = 1:length(sectionList)
    [S(sectionList(i)),tf(sectionList(i))] = ScanText_GTA(sectionList(i),outputPath,slot_mask_file,section_mask_file, focus_mask_file);
    f = fullfile(outputPath,[num2str(sectionList(i)),'.txt']);
    
    fid = fopen(f, 'rt');
    s = textscan(fid, '%s', 'delimiter', '\n');
    
    idx1 = find(strcmp(s{1}, 'SLOT'), 1, 'first');
    idx2 = find(strcmp(s{1}, 'TOLS'), 1, 'first');
    slot = dlmread(f,'',[idx1 0 idx2-2 1]);
    
    idx3 = find(strcmp(s{1}, 'SECTION'), 1, 'first');
    idx4 = find(strcmp(s{1}, 'NOITCES'), 1, 'first');
    section = dlmread(f,'',[idx3 0 idx4-2 1]);
    
    idx5 = find(strcmp(s{1}, 'FOCUS'), 1, 'first');
    idx6 = find(strcmp(s{1}, 'SUCOF'), 1, 'first');
    focus = [];
    hasFocus = 0;
    
%     idx = find(strcmp(s{1},'SECTIONCOM(x,y,theta):'), 1, 'first');
%     xyTH = dlmread(f,'',[idx 0 idx 2]);
%     xy = xyTH(1:2);
%     angle = xyTH(3); % note this is not accurate!

    idx5 = find(strcmp(s{1}, 'FLAGS'), 1, 'first');
    flags = dlmread(f,'',[idx5+1 0 idx5+1 1]);
    isproblematic = flags(1);
    isverified = flags(2);
    
    fclose(fid);
    
    %% Determine scale and center of slot
    % assume convention of 8 sided mask, starting from bottom left
    % 170703_slot_mask
    
    % find edges of slot in units of pixels
    xL = (slot(1,1)+slot(2,1))/2;
    xR = (slot(5,1)+slot(6,1))/2;
    yT = (slot(3,2)+slot(4,2))/2;
    yB = (slot(7,2)+slot(8,2))/2;
    
    slot_center_pxl = [(xR+xL)/2 (yB+yT)/2];
    slot_size_pxl = [(xR-xL) (yB-yT)];
    pxl_size = 5.3; %um, point grey camera
    pxl_scale = 1000/pxl_size/1e6; % pxls per nm 
    %pxl_scale = [slot_size(1)/2 slot_size(2)/1.5]; % pixels per mm
    
    
    %% Place ROI
    
    disp(['Sect ' num2str(sectionList(i)) ': ']);
    
    % Get ROI mask vertices (masks format)
    fid2 = fopen(ROI_mask_file, 'rt');
    ROI_ref = dlmread(ROI_mask_file,' ',1,0);
    fclose(fid2);
    
    % Rotate ROI back to ref mask
    ROIvert_mask = RotateMaskVertices(ROI_ref,delta_angle,section_xy)-delta_xy;      
    % ROIvert_mask is the ROI in the original mask reference frame26-Jun-2018_499-499_corner_2.json
    
    % Calculate section COM and angles
    xy = [mean(section(:,1)),mean(section(:,2))];
    relative_xy = xy - section_mask_xy;
    
    %section_angle = section_xyTH(3); %angles are not accurate!
    angle_ref = section(3,:)-section(2,:);
    angle = atan(angle_ref(2)/angle_ref(1));
    relative_angle = angle - section_mask_angle;

    % Rotate and translate vertices to match section mask
    % Rotation should be with respect to the section masks' COM
    ROIvert = RotateMaskVertices(ROIvert_mask,-relative_angle,section_mask_xy)+relative_xy;
    %ROIvert_nm = round((ROIvert-slot_center_pxl)./pxl_scale);

    % Focus point
    if hasFocus
        focus_pxl_x = focus(1,1)-slot_center_pxl(1);
        focus_pxl_y = focus(1,2)-slot_center_pxl(2);
        focus_nm = [focus_pxl_x,focus_pxl_y]/pxl_scale;
        focus_nm = -focus_nm;
        focus_nm = round(focus_nm);
    end
    
    %% Crop ROI to slot boundaries
    
    ROIpoly = polyshape(ROIvert(:,1), ROIvert(:,2));
    slotpoly = polyshape(slot(:,1),slot(:,2));
    ROI_crop_poly = intersect(ROIpoly, slotpoly);
    ROI_crop = ROI_crop_poly.Vertices;
    
    % Convert ROI to nm and slot-centric coordinates 
    ROInm = round((ROI_crop-slot_center_pxl)./pxl_scale); 
    
    % Calculate bounding box 
    right_edge_nm = max(ROInm(:,1)); 
    left_edge_nm = min(ROInm(:,1));
    top_edge_nm = min(ROInm(:,2)); % top is y smaller on scope
    bottom_edge_nm = max(ROInm(:,2));
    width_nm = right_edge_nm - left_edge_nm;
    height_nm = bottom_edge_nm - top_edge_nm;
    
    %% Write json entry
    if write_json == 1
        vertices=', "vertices": [';
        for vertex = ROInm'
            vertices=[vertices '[' num2str((vertex(1)-(right_edge_nm-width_nm))/width_nm) ', ' num2str((vertex(2)-top_edge_nm)/height_nm) '], '];
        end
        vertices=[vertices(1:length(vertices)-2) ']'];
        
        fprintf(fileID,['"' num2str(sectionList(i)) '": {"rois": [{"width": ' num2str(width_nm) ', "right": ' ...
            sprintf('%0.0f',right_edge_nm) ', "top": ' sprintf('%0.0f',top_edge_nm)...
            ', "height": ' num2str(height_nm) vertices '}]']);
        if hasFocus
            fprintf(fileID,[',"focus_points":[[' num2str(focus_nm(1)) ',' num2str(focus_nm(2)) ']]']);
        end
        fprintf(fileID,'}');
        if sectionList(i) == sectionList(end)
            fprintf(fileID,'}');
        else
            fprintf(fileID,', ');
        end
    %{    
    if write_json == 1
        if tapedir == 1
            fprintf(fileID,['"' num2str(sectionList(i)) '": {"rois": [{"width": ' num2str(width_nm) ', "right": ' ...
                sprintf('%0.0f',right_edge_nm) ', "top": ' sprintf('%0.0f',top_edge_nm)...
                ', "height": ' num2str(height_nm) '}]']);
        elseif tapedir == -1
                fprintf(fileID,['"' num2str(sectionList(i)) '": {"rois": [{"width": ' num2str(width_nm) ', "left": ' ...
                    sprintf('%0.0f',right_edge_nm) ', "bottom": ' sprintf('%0.0f',top_edge_nm)...
                    ', "height": ' num2str(height_nm) '}]']);
        end
        if hasFocus
        fprintf(fileID,[',"focus_points":[[' num2str(focus_nm(1)) ',' num2str(focus_nm(2)) ']]']);
        end    
        fprintf(fileID,'}');
        if sectionList(i) == sectionList(end)
            fprintf(fileID,'}');
        else
            fprintf(fileID,', ');
        end        
      %}  
        %{
fprintf(fileID,['"' num2str(sectionList(i)) '": {"rois": [{"width": 100000, "center": [' ...
    sprintf('%0.0f',1e6*roi_TR_nm_fudged(1)) ', ' sprintf('%0.0f',1e6*roi_TR_nm(2)_fudged) '], "height": 100000}]}']);
if sectionList(i) == endSectionID
    fprintf(fileID,'}');
else
    fprintf(fileID,', ');
end
        %}       
    end
    %% Plot and save annotation image
    
    if plot_imgs == 1
               
        im_raw = imread([imPath '/' num2str(sectionList(i)) '.png']);
        figure(hfig1);
        channel = 3; % blue channel seems to be the most informative
        num_levels = 20; % number of levels for histogram equalization
        A2 = histeq(im_raw(:,:,3),20);
        A1 = A2;
        imshow(A1,jet(225)); axis equal; axis off; hold on;
        hold on; 
        % plot slot center
        plot(slot_center_pxl(:,1),slot_center_pxl(:,2),'mo','Linewidth',3);
        
        if hasFocus
            plot(focus(:,1), focus(:,2), 'ro', 'Linewidth',4);
        end
        
        % plot section outline
        section_outline = vertcat(section, section(1,:));
        %section_outline = vertcat(section_mask_orig, section_mask_orig(1,:));       
        plot(section_outline(:,1),section_outline(:,2),'w-','Linewidth',2); 
        %plot(section_outline(:,1),section_outline(:,2),'w-','Linewidth',2)
        
        % plot ROI outline
        %ROI_outline = vertcat(ROIvert_mask, ROIvert_mask(1,:));
        ROI_outline = vertcat(ROI_crop, ROI_crop(1,:));
        %ROI_outline = vertcat(section_mask_calc, section_mask_calc(1,:)); 
        plot(ROI_outline(:,1),ROI_outline(:,2),'c-','Linewidth',2)

        timestamp = datetime('now');
        title(['sect ' num2str(sectionList(i)) ' ' datestr(timestamp)]);
        hold off;
        %pause(1)
        %{
        % plot ROI
        % generate ROI for plotting in annot images
        % move backwards from values sent to json file
        %corner_pxl = -([right_edge_nm top_edge_nm]-fudge_factor)*pxl_scale + slot_center_pxl;
        corner_pxl = ([right_edge_nm top_edge_nm]-fudge_factor)*pxl_scale + slot_center_pxl;
        

        if tapedir == 1
        rect_ROI = vertcat(corner_pxl,corner_pxl+[0 -height_nm*pxl_scale],...
            corner_pxl+[width_nm*pxl_scale -height_nm*pxl_scale],...
            corner_pxl+[width_nm*pxl_scale 0], corner_pxl);
        elseif tapedir == -1
        rect_ROI = vertcat(corner_pxl,corner_pxl+[0 height_nm*pxl_scale],...
            corner_pxl+[width_nm*pxl_scale height_nm*pxl_scale],...
            corner_pxl+[width_nm*pxl_scale 0], corner_pxl);
        end
        plot(rect_ROI(:,1),rect_ROI(:,2),'c-','Linewidth',3);
        
            %}
        F = frame2im(getframe(hfig1));%im2frame(C);
        img_save_path = [masterPath '/annot_imgs/' num2str(sectionList(i)) '.png'];
        imwrite(F,img_save_path);
    
    end
    
end
%% close json file
if write_json == 1
    fclose(fileID);
end