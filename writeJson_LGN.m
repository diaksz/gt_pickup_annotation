
%% ATK 170703

startSectionID = 1;
endSectionID = 58;
skipList = [9];
write_json = 1;
plot_imgs = 1;
sectionList = [31, 32, 58]; %startSectionID:endSectionID;
sectionList = setdiff(sectionList,skipList);
%% Set paths and load mask and image
% master path
if ispc
    masterPath = K'/home/lab/LGN_0084';
elseif isunix
    masterPath = '/home/lab/LGN_0084';
else
    disp('OS error - not Win or Unix');
end
queue_output = [masterPath '/queues/lgn3696_r084_' date '_' num2str(startSectionID) '-' num2str(endSectionID) '.json'];

% saved mask templates for slot and section, respectively, in txt
slot_mask_file = [masterPath '/masks/' 'slot_mask_sect0010_170705.txt'];
section_mask_file = [masterPath '/masks/' 'section_mask_lgn_0084_sect54.txt'];
%setappdata(hfig,'slot_mask_file',slot_mask_file);
%setappdata(hfig,'section_mask_file',section_mask_file);

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
   
for i = 1:length(sectionList)
    [S(sectionList(i)),tf(sectionList(i))] = ScanText_GTA(sectionList(i),outputPath,slot_mask_file,section_mask_file);
    f = fullfile(outputPath,[num2str(sectionList(i)),'.txt']);
    
    fid = fopen(f, 'rt');
    s = textscan(fid, '%s', 'delimiter', '\n');
    
    idx1 = find(strcmp(s{1}, 'SLOT'), 1, 'first');
    idx2 = find(strcmp(s{1}, 'TOLS'), 1, 'first');
    slot = dlmread(f,'',[idx1 0 idx2-2 1]);
    
    idx3 = find(strcmp(s{1}, 'SECTION'), 1, 'first');
    idx4 = find(strcmp(s{1}, 'NOITCES'), 1, 'first');
    section = dlmread(f,'',[idx3 0 idx4-2 1]);
    
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
    
    
    %% Determine ROI (TEM reference)
    % assume convention of this being the first point
    % 170703_section_mask
    
    disp(['Sect ' num2str(sectionList(i)) ': ']);
    
    % units are nm
    offset_nm = 20000; %AK 170809 reduced to 20, based on stdev of 16 um
    width_nm = 700000+2*offset_nm;
    height_nm = 860000+2*offset_nm;

    
    roi_TR_pxl_x = 0.72*section(2,1) + 0.28*section(5,1)-slot_center_pxl(1);
    roi_TR_pxl_y = 0.5*section(1,2) + 0.5*section(6,2)-80-slot_center_pxl(2);
    
    %roi_TR_pxl = section(1,:)-slot_center_pxl;
    roi_TR_nm = [roi_TR_pxl_x,roi_TR_pxl_y]/pxl_scale;  
    roi_TR_nm = -roi_TR_nm; % rotate 180 deg to match TEMCA-GT orientation
    
  
    % check if corner is too close to slot (only checks bottom left (top right) for now)
    slot_padding = -40000+offset_nm; % closest we allow the corner to be to slot
    % AK adjusted slot_padding 170817
    % for now, treat the slot as 2x1.5, padding comes for free
    
    % check x
    if roi_TR_nm(1) > 1e6-slot_padding
        width_nm = width_nm - (roi_TR_nm(1)-(1e6-slot_padding)); % reduce ROI accordingly
        roi_TR_nm(1) = 1e6-slot_padding;
        disp('Corner off slot right, adjusting ROI');
    end
    
    % check y
    if roi_TR_nm(2) < -.75*1e6+slot_padding;
        height_nm = height_nm - (roi_TR_nm(2)-(-.75*1e6+slot_padding)); % reduce ROI accordingly
        roi_TR_nm(2) = -.75*1e6+slot_padding;
        disp('Corner off slot up, adjusting ROI');
    end
    
%     % check rounded corner
%     chamfer_center = [.5 -.25]*1e6;
%     chamfer_radius = 0.5*1e6;
%     offsetTR = [roi_TR_nm(1)-chamfer_center(1) roi_TR_nm(2)-chamfer_center(2)];
%     
%     if offsetTR(1) > 0 && offsetTR(2) < 0 && norm(offsetTR) > chamfer_radius - slot_padding
%         roi_TR_nm = chamfer_center + (chamfer_radius-slot_padding)/norm(offsetTR)*offsetTR;
%         disp_chamfer = offsetTR-(chamfer_radius-slot_padding)/norm(offsetTR)*offsetTR;
%         width_nm = width_nm - abs(disp_chamfer(1));
%         height_nm = height_nm - abs(disp_chamfer(2));
%         disp('Corner off slot top right, adjusting ROI');
%     end

    
    
    %%%%%%%%%%%%%%%%%%%%%%%% TEMCA-GT FUDGE FACTOR %%%%%%%%%%%%%%%%%%%%%
    % add constant offset to account for slot-finding routine offset
    % fudge_factor = [ mean([.8921-.8515 .9581-.9422]) mean([-.4332+.5335 -.4062+.4968])];
    % This is from manual checking of sec 431 and 432
    %fudge_factor = [0.0282    0.0955]*1e6;
    
    % AK 170719 updated fudgefactor based on coarse montages 520-532
    % X: -56 um (3.5 blocks) Y: -8 um (0.5 blocks)
    %fudge_factor = [-0.0278    0.0875]*1e6;

    % AK 170809 updated fudgefactor based on coarse montages
    % 1000-1042
    % X: +, most off montage (add back 30 um), Y: 56-30 = 26 um
    % Y stdev = 16 um (1 block)
    fudge_factor = [0.0022    0.1135]*1e6;
    
    roi_TR_nm_fudged = roi_TR_nm + fudge_factor;
    right_edge_nm = roi_TR_nm_fudged(1)+offset_nm; 
    top_edge_nm = roi_TR_nm_fudged(2)-offset_nm;
    
    disp(['Top Right Corner: ' num2str(roi_TR_nm_fudged)]);
    
    % Round to integers for microscope.
    width_nm = round(width_nm);
    height_nm = round(height_nm);
    right_edge_nm = round(right_edge_nm);
    top_edge_nm = round(top_edge_nm);
    
    %% Write json entry

    if write_json == 1
        fprintf(fileID,['"' num2str(sectionList(i)) '": {"rois": [{"width": ' num2str(width_nm) ', "right": ' ...
            sprintf('%0.0f',right_edge_nm) ', "top": ' sprintf('%0.0f',top_edge_nm)...
            ', "height": ' num2str(height_nm) '}]}']);
        if sectionList(i) == endSectionID
            fprintf(fileID,'}');
        else
            fprintf(fileID,', ');
        end        
        
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
        
        % Preprocess image to make easier to see edges
left_crop = 300;%250;
right_crop = 1280;%1280;
top_crop = 250;%250;
bottom_crop = 850;%750;
        channel = 3; % blue channel seems to be the most informative
        num_levels = 20; % number of levels for histogram equalization
        A2 = histeq(im_raw(top_crop:bottom_crop,left_crop:right_crop,3),20);
        A1 = A2;
        
        imshow(A1,jet(225)); axis equal; axis off; hold on;
        
        % plot slot center
        plot(slot_center_pxl(:,1),slot_center_pxl(:,2),'mo','Linewidth',3);
        
        % plot section outline
        section_outline = vertcat(section, section(1,:));
        plot(section_outline(:,1),section_outline(:,2),'w-','Linewidth',2)
        timestamp = datetime('now');
        title(['sect ' num2str(sectionList(i)) ' ' datestr(timestamp)]);
        
        
        % plot ROI
        % generate ROI for plotting in annot images
        % move backwards from values sent to json file
        corner_pxl = -([right_edge_nm top_edge_nm]-fudge_factor)*pxl_scale + slot_center_pxl;
        
        rect_ROI = vertcat(corner_pxl,corner_pxl+[0 -height_nm*pxl_scale],...
            corner_pxl+[width_nm*pxl_scale -height_nm*pxl_scale],...
            corner_pxl+[width_nm*pxl_scale 0], corner_pxl);
        plot(rect_ROI(:,1),rect_ROI(:,2),'c-','Linewidth',3);
        
        
        F = frame2im(getframe(hfig1));%im2frame(C);
        img_save_path = [masterPath '/annot_imgs/' num2str(sectionList(i)) '.png'];
        imwrite(F,img_save_path);
    end
    
end
%% close json file
if write_json == 1
    fclose(fileID);
end