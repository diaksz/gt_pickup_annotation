function hfig = GridTapeAlign
%% Make figure
scrn = get(0,'Screensize');
hfig = figure('Position',[scrn(3)*0 scrn(4)*0 scrn(3)*1 scrn(4)*1],...% [50 100 1700 900]
    'Name','GridTapeAlign','DeleteFcn',@closefigure_Callback,...
    'KeyPressFcn',@KeyPressCallback,...
    'WindowButtonDownFcn',@WindowButtonDownCallback,...
    'ToolBar', 'none'); % 'MenuBar', 'none'
hold off; axis off

% init GUI drawing axes
ax_pos = [0.1, 0.1, 0.8, 0.7];
% setappdata(hfig,'ax_pos',ax_pos);
figure(hfig);
h_ax = axes('Position',ax_pos);
axis image
% axes(h_ax);

%% Set paths and load mask and image
% master path
if ispc
    masterPath = '/home/lab/gut';
    %masterPath = '/home/lab/170601_P26_Emx_SHH_wt2_r130';
elseif isunix
    masterPath = '/home/lab/gut';
    %masterPath = '/home/lab/170601_P26_Emx_SHH_wt2_r130';
else
    disp('OS error - not Win or Unix');
end
        
% saved mask templates for slot and section, respectively, in txt
slot_mask_file = [masterPath '/masks/' 'slotMask.txt'];
section_mask_file = [masterPath '/masks/' 'section_3_mask.txt'];
focus_mask_file = [masterPath '/masks/' 'focus_mask.txt'];

setappdata(hfig,'slot_mask_file',slot_mask_file);
setappdata(hfig,'section_mask_file',section_mask_file);
%setappdata(hfig,'
% output of annotation, in txt
outputPath = [masterPath '/annotations']; % saves annotated relative positions to txt, for each individual section
if exist(outputPath,'dir')~=7
    mkdir(outputPath);
end
setappdata(hfig,'outputPath',outputPath);

% image folder
imPath = [masterPath '/img_links']; % contains images of individual sections
ParseImageDir(hfig,imPath);

%% Init section
% load first section
i_im = 1;
setappdata(hfig,'i_im',i_im);
secID = GetSectionIDfromCounter(hfig,i_im);
S = ScanText_GTA(secID,outputPath,slot_mask_file,section_mask_file);
setappdata(hfig,'S',S);
LoadNewMask(hfig,slot_mask_file,section_mask_file);

% structure for individual slots:
% S = [];
% S.secID = secID;
% S.maskFile = maskFile;
% S.slot.translation = [0,0];
% S.slot.rotation = 0;
% S.section.translation = [0,0];
% S.section.rotation = 0;
% S.is_problematic = 0;
% S.is_verified = 0;
   
%% Create UI controls
set(gcf,'DefaultUicontrolUnits','normalized');
set(gcf,'defaultUicontrolBackgroundColor',[1 1 1]);

% tab group setup
tgroup = uitabgroup('Parent', hfig, 'Position', [0.05,0.88,0.91,0.12]);
numtabs = 2;
tab = cell(1,numtabs);
M_names = {'General','Init'};%,'Regression','Clustering etc.','Saved Clusters','Atlas'};
for i = 1:numtabs,
    tab{i} = uitab('Parent', tgroup, 'BackgroundColor', [1,1,1], 'Title', M_names{i});
end

% grid setup, to help align display elements
rheight = 0.2;
yrow = 0.7:-0.33:0;%0.97:-0.03:0.88;
dTextHt = 0.05; % dTextHt = manual adjustment for 'text' controls:
% (vertical alignment is top instead of center like for all other controls)
bwidth = 0.03;
grid = 0:bwidth+0.001:1;

%% handles
global h_i_im h_secID h_imdir h_outputdir h_probflag h_verflag

%% UI ----- tab one ----- (General)
i_tab = 1;

%% UI row 1: file navigation
i_row = 1;
i = 1;n = 0;

i=i+n;
n=2; % saves both to workspace and to 'VAR_current.mat' and to arc folder
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Set output dir',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_getoutputdir_Callback);

i=i+n;
n=6;
h_outputdir = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'String',outputPath,'enable', 'off');

i=i+n;
n=2;
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Set image dir',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_getimagedir_Callback);

i=i+n;
n=6;
h_imdir = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'String',imPath,'enable', 'off');

i=i+n;
n=2;
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Set mask files',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_getmasksdir_Callback);



%% UI row 2: current section
i_row = 2;
i = 1;n = 0;

i=i+n;
n=2;
uicontrol('Parent',tab{i_tab},'Style','text','String','Section count:',...
    'Position',[grid(i) yrow(i_row)-dTextHt bwidth*n rheight],'HorizontalAlignment','right');

i=i+n;
n=2;
h_i_im = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@edit_imageCount_Callback);

i=i+n;
n=2;
uicontrol('Parent',tab{i_tab},'Style','text','String','Section ID:',...
    'Position',[grid(i) yrow(i_row)-dTextHt bwidth*n rheight],'HorizontalAlignment','right');

i=i+n;
n=2;
h_secID = uicontrol('Parent',tab{i_tab},'Style','edit',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@edit_secID_Callback);

i=i+n+1;
n=3;
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Previous(''Shift+rClick'')',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_loadPreviousImage_Callback);

i=i+n;
n=3;
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Next(''Right Click'')',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_loadNextImage_Callback);

i=i+n;
n=2;
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Reset Masks',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_resetMasks_Callback);
%% UI row 3: create masks, and flags
i_row = 3;
i = 1;n = 0;

i=i+n;
n=4; % saves both to workspace and to 'VAR_current.mat' and to arc folder
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Make new slot mask',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_createSlotMask_Callback);

i=i+n;
n=4; % saves both to workspace and to 'VAR_current.mat' and to arc folder
uicontrol('Parent',tab{i_tab},'Style','pushbutton','String','Make new section mask',...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@pushbutton_createSectionMask_Callback);

i=i+n;
n=3; % popupplot option: whether to plot behavior bar
h_probflag = uicontrol('Parent',tab{i_tab},'Style','checkbox','String','problematic?','Value',0,...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@checkbox_isProblematicFlag_Callback);

i=i+n;
n=3; % popupplot option: whether to plot behavior bar
h_verflag = uicontrol('Parent',tab{i_tab},'Style','checkbox','String','verified?','Value',0,...
    'Position',[grid(i) yrow(i_row) bwidth*n rheight],...
    'Callback',@checkbox_isVerifiedFlag_Callback);

%% Init load
LoadImage(hfig,i_im);

end

%% Callback functions for UI elements:

%% ----- tab one ----- (General)

%% row 1: file navigation
function pushbutton_getimagedir_Callback(hObject,~)
hfig = getParentFigure(hObject);
start_path = getappdata(hfig,'imPath');
folder_name = uigetdir(start_path,'Choose folder containing images of sections');

global h_imdir
if folder_name~=0
    imPath = folder_name;
    ParseImageDir(hfig,imPath);
    h_imdir.String = imPath;    
    
    % Load first image
    i_im = 1;
    setappdata(hfig,'i_im',i_im);
    LoadImage(hfig,i_im);
end
end

function pushbutton_getmasksdir_Callback(hObject,~)
hfig = getParentFigure(hObject);
[FileName1,PathName] = uigetfile('*.txt','Select the txt file for slot mask');
slot_mask_file = fullfile(PathName,FileName1);
[FileName2,PathName] = uigetfile('*.txt','Select the txt file for slot mask');
section_mask_file = fullfile(PathName,FileName2);

if isequal(FileName1,0) || isequal(FileName2,0),
    disp('User selected Cancel')
else
    try
        LoadNewMask(hfig,slot_mask_file,section_mask_file);
        % reload current image
        i_im = getappdata(hfig,'i_im');
        LoadImage(hfig,i_im);
        
        % (set path if didn't crash)
        setappdata(hfig,'slot_mask_file',slot_mask_file);
        setappdata(hfig,'section_mask_file',section_mask_file);
    catch
        errordlg('failed to load new masks');
    end
end
end

function pushbutton_getoutputdir_Callback(hObject,~)
hfig = getParentFigure(hObject);
start_path = getappdata(hfig,'outputPath');
folder_name = uigetdir(start_path,'Choose folder in which to save alignment info (txt files)');

global h_outputdir
if folder_name~=0
    h_outputdir.String = imPath;
    setappdata(hfig,'outputPath',folder_name);
end
end

%% row 2: current section
function edit_imageCount_Callback(hObject,~)
hfig = getParentFigure(hObject);
% get/format range
str = get(hObject,'String');
if ~isempty(str),
    C = textscan(str,'%d');
    i_im = C{1}; % C{:};
    
    LoadImage(hfig,i_im);
end
end

function edit_secID_Callback(hObject,~)
hfig = getParentFigure(hObject);
% get/format range
str = get(hObject,'String');
if ~isempty(str),
    C = textscan(str,'%d');
    secID = C{1}; % C{:};
    
    i_im = GetCounterFromSectionID(hfig,secID);
    LoadImage(hfig,i_im);
end
end

function pushbutton_loadPreviousImage_Callback(hObject,~)
hfig = getParentFigure(hObject);
LoadPreviousImage(hfig);
end

function pushbutton_loadNextImage_Callback(hObject,~)
hfig = getParentFigure(hObject);
LoadNextImage(hfig);
end

function pushbutton_resetMasks_Callback(hObject,~)
hfig = getParentFigure(hObject);
slot_mask_file = getappdata(hfig,'slot_mask_file');
section_mask_file = getappdata(hfig,'section_mask_file');
hpoly = getappdata(hfig,'hpoly');
delete(hpoly);
LoadNewMask(hfig,slot_mask_file,section_mask_file);
DrawNewMask(hfig)
end

%% row 3: create masks, flags

function pushbutton_createSlotMask_Callback(hObject,~)
hfig = getParentFigure(hObject);
h = impoly;
setColor(h,[1 1 1]);
wait(h); % double click to finalize position!
% update finalized polygon in red color
setColor(h,[1 0 0]);

pos = getPosition(h);

% save to file
[file,path] = uiputfile('slot_mask.txt','Save file name');

% write to file
f = fullfile(path,file);
setappdata(hfig,'slot_mask_file',f);

% (write to txt)
fileID = fopen(f,'wt');
fprintf(fileID,'%s\n','row: vertices; col: x & y coordinate');
for i = 1:size(pos,1)
    formatSpec = '%4.2f %4.2f\n';
    fprintf(fileID,formatSpec,pos(i,1),pos(i,2));
end
fclose(fileID);
end

function pushbutton_createSectionMask_Callback(hObject,~)
hfig = getParentFigure(hObject);
h = impoly;
setColor(h,[1 1 1]);
wait(h); % double click to finalize position!
% update finalized polygon in red color
setColor(h,[1 0 0]);

pos = getPosition(h);

% save to file
[file,path] = uiputfile('section_mask.txt','Save file name');

% write to file
f = fullfile(path,file);
setappdata(hfig,'section_mask_file',f);

% (write to txt)
fileID = fopen(f,'wt');
fprintf(fileID,'row: vertices; col: x & y coordinate\n');
for i = 1:size(pos,1)
    formatSpec = '%4.2f %4.2f\n';
    fprintf(fileID,formatSpec,pos(i,1),pos(i,2));
end
fclose(fileID);
end

function checkbox_isProblematicFlag_Callback(hObject,~)
hfig = getParentFigure(hObject);
S = getappdata(hfig,'S');
S.is_problematic = get(hObject,'Value');
setappdata(hfig,'S',S);
end

function checkbox_isVerifiedFlag_Callback(hObject,~)
hfig = getParentFigure(hObject);
S = getappdata(hfig,'S');
S.is_verified = get(hObject,'Value');
setappdata(hfig,'S',S);
end

%% UI-level functions

function KeyPressCallback(hfig, event)
global h_probflag h_verflag
masktypeID = getappdata(hfig,'masktypeID');
if strcmp(event.Key,'space')
    % switch between mask types (slot vs section)
    masktypeID = ToggleSelectedMask(hfig);
    
    % flags
elseif strcmp(event.Key,'p') % check 'is_problematic' flag
    h_probflag.Value = 1;
    S = getappdata(hfig,'S');
    S.is_problematic = 1;
    setappdata(hfig,'S',S);

elseif strcmp(event.Key,'v') % check 'is_verified' flag    
    h_verflag.Value = 1;
    S = getappdata(hfig,'S');
    S.is_verified = 1;
    setappdata(hfig,'S',S);
    
    % Translations

elseif strcmp(event.Key,'a') % translation: left
    translationArray = [-1,0];
    TranslateMask(hfig,translationArray,masktypeID);
    
elseif strcmp(event.Key,'d') % translation: right
    translationArray = [1,0];
    TranslateMask(hfig,translationArray,masktypeID);
    
elseif strcmp(event.Key,'w') % translation: up
    translationArray = [0,-1];
    TranslateMask(hfig,translationArray,masktypeID);
    
elseif strcmp(event.Key,'s') % translation: down
    translationArray = [0,1];
    TranslateMask(hfig,translationArray,masktypeID);
    
    % Rotations
    
elseif strcmp(event.Key,'q') % rotation: counter-clockwise
    rotationAngle = 0.005;
    RotateMask(hfig,rotationAngle,masktypeID);
    
elseif strcmp(event.Key,'e') % translation: clockwise
    rotationAngle = -0.005;
    RotateMask(hfig,rotationAngle,masktypeID);
    
end
end

function WindowButtonDownCallback(hfig, event)
seltype = get(gcf,'SelectionType');
switch seltype
    case 'extend' % Shift-click
        LoadPreviousImage(hfig);
    case 'alt' % RightClick/Control-click
        LoadNextImage(hfig);
        %     case 'open' % double left click
        %         disp(['double'])
        %     case 'normal' % normal single left click
        %         disp(['normal'])
end
end

function closefigure_Callback(hfig,~)
SaveCurrentMasks(hfig);

global EXPORT_autorecover;
EXPORT_autorecover = getappdata(hfig);
end

%% Helper functions

function ParseImageDir(hfig,imPath)
setappdata(hfig,'imPath',imPath);
imList = dir(fullfile(imPath, '*png'));
numFiles = length(imList);

fileIDs = zeros(numFiles,1);
% validIX = 1:numFiles0;
try
    for i = 1:numFiles
        a = imList(i).name;
        if length(a)>12 && strcmp(a(end-11:end),'_section.png')
            str = a(end-15:end-12);
            if str(1)=='_'
                str(1) = [];
            end
            C = textscan(str,'%d');
            fileIDs(i) = C{1};
        else
            %     if strcmp(a(end-3:end),'.png')
            str = a(1:end-4);
            C = textscan(str,'%d');
            
            fileIDs(i) = C{1};
            
            %     else
            %         validIX(i) = 0;
            %         disp(['fLiile ''',a,''' does not match expected file name format']);
        end
    end
catch
    errordlg('folder contains files with unexpected file names');
end
% numFiles = length(find(validIX));
[sectionIDs,IX] = sort(fileIDs);

List = [];
List.filenames = {imList(IX).name}';
List.sectionIDs = sectionIDs;

setappdata(hfig,'List',List);
setappdata(hfig,'numFiles',numFiles);
end
    
function secID = GetSectionIDfromCounter(hfig,i_im)
List = getappdata(hfig,'List');
secID = List.sectionIDs(i_im);
setappdata(hfig,'secID',secID);
end

function i_im = GetCounterFromSectionID(hfig,secID)
List = getappdata(hfig,'List');
i_im = find(ismember(List.sectionIDs,secID),1,'first');
if ~isempty(i_im)
    setappdata(hfig,'i_im',i_im);
else
    i_im = getappdata(hfig,'i_im');
    disp('section ID invalid - image not found');
end
end

function SaveCurrentMasks(hfig)
S = getappdata(hfig,'S');
secID = getappdata(hfig,'secID');
outputPath = getappdata(hfig,'outputPath');

% update current pos stored in M (in case of unrecorded dragging of ROI)
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');
masktypeID = getappdata(hfig,'masktypeID');
if ~isempty(hpoly) % (first load exception)
    M(masktypeID).pos = getPosition(hpoly(masktypeID));
    setappdata(hfig,'M',M);
end

% update S data (relangle is updated directly through Rotation function)
S.slot.translation = GetCenterPos(M(1).pos) - GetCenterPos(M(1).pos_init);
S.section.translation = GetCenterPos(M(2).pos) - GetCenterPos(M(2).pos_init);

setappdata(hfig,'S',S);

% write to text file
WriteToText_GTA(secID,S,M,outputPath);
end

function LoadImage(hfig,i_im)
%% save mask positions for previous image
SaveCurrentMasks(hfig);

%% load new file
setappdata(hfig,'i_im',i_im); % set new image index
secID = GetSectionIDfromCounter(hfig,i_im);

% try to load txt data, if exist (otherwise just init)
outputPath = getappdata(hfig,'outputPath');
slot_mask_file = getappdata(hfig,'slot_mask_file');
section_mask_file = getappdata(hfig,'section_mask_file');
focus_mask_file = getappdata(hfig,'focus_mask_file')
[S,tf] = ScanText_GTA(secID,outputPath,slot_mask_file,section_mask_file);
setappdata(hfig,'S',S);

% %% set flags and set pos from file
% global h_probflag h_verflag
% 
% % setup mask position from info saved in S
% if tf % (if annotation file exists)
%     disp([num2str(i_im),': sectionID = ',num2str(secID)]);
%     S = getappdata(hfig,'S');
% 
%     pos_slot_init = dlmread(slot_mask_file,' ',1,0);
%     pos_section_init = dlmread(section_mask_file,' ',1,0);
%     
%     % init mask struct
%     M = [];
%     
%     masktypeID = 1;
%     M(masktypeID).pos_init = pos_slot_init;
%     
%     masktypeID = 2;
%     M(masktypeID).pos_init = pos_section_init;
%     
%     pos_slot = S.slot.vertices;
%     pos_section = S.section.vertices;
% 
%     M(1).pos = pos_slot;
%     M(2).pos = pos_section;
%     
%     setappdata(hfig,'M',M);
%     
%     %% load flags
%     h_probflag.Value = S.is_problematic;
%     h_verflag.Value = S.is_verified;
% else
%     LoadNewMask(hfig,slot_mask_file,section_mask_file);
%     h_probflag.Value = 0;
%     h_verflag.Value = 0;
% end

%% update GUI
global h_i_im;
h_i_im.String = num2str(i_im);

global h_secID;
h_secID.String = num2str(secID);

%% load new image
imPath = getappdata(hfig,'imPath');
List = getappdata(hfig,'List');
im_raw = imread(fullfile(imPath,List.filenames{i_im}));

%% draw image
% clean-up canvas
allAxesInFigure = findall(hfig,'type','axes');
if ~isempty(allAxesInFigure)
    delete(allAxesInFigure);
end
% ax_pos = getappdata(hfig,'ax_pos');
% figure(hfig);
% h_ax = axes('Position',ax_pos);
% h_ax = getappdata(hfig,'h_ax');
axes(gca);

% Preprocess image to make easier to see edges
left_crop = 1;%250;
right_crop = 1100;%1280;
top_crop = 200;
bottom_crop = 750;
channel = 3; % blue channel seems to be the most informative
num_levels = 20; % number of levels for histogram equalization
%imshow(histeq(im_raw(top_crop:bottom_crop,left_crop:right_crop,3),20),gray(255));
%imshow(histeq(im_raw(top_crop:bottom_crop,left_crop:right_crop,3),20),jet(255));
image(im_raw(top_crop:bottom_crop,left_crop:right_crop,:));
%imagesc(im_raw);
axis equal; axis off
% setappdata(hfig,'im_raw',im_raw);
% setappdata(hfig,'h_ax',h_ax);

%% set flags and set pos from file
global h_probflag h_verflag

% setup mask position from info saved in S
if tf % (if annotation file exists)
    disp([num2str(i_im),': sectionID = ',num2str(secID)]);
    S = getappdata(hfig,'S');

    pos_slot_init = dlmread(slot_mask_file,' ',1,0);
    pos_section_init = dlmread(section_mask_file,' ',1,0);
    
    % init mask struct
    M = [];
    
    masktypeID = 1;
    M(masktypeID).pos_init = pos_slot_init;
    
    masktypeID = 2;
    M(masktypeID).pos_init = pos_section_init;
    
    pos_slot = S.slot.vertices;
    pos_section = S.section.vertices;

    M(1).pos = pos_slot;
    M(2).pos = pos_section;
    
    setappdata(hfig,'M',M);
    
    %% load flags
    h_probflag.Value = S.is_problematic;
    h_verflag.Value = S.is_verified;
else
    LoadNewMask(hfig,slot_mask_file,section_mask_file);
    h_probflag.Value = 0;
    h_verflag.Value = 0;
    
%% find slot - LAT's threshold-and-label algorithm
    % this threshold is somewhat arbitrary...
    bin_img = imbinarize(rgb2gray(im_raw(top_crop:bottom_crop,left_crop:right_crop,:)), .2);
    % remove all small white dots (under 5000 pixel areas)
    bin_img = bwareaopen(bin_img,5000);
    bin_img = ~bin_img;
    % remove all small black dots ( under 5000 pixel areas)
    bin_img = bwareaopen(bin_img,5000);
    % get connnected components
    cc = bwconncomp(bin_img);
    if cc.NumObjects >= 1
        numPixels = cellfun(@numel, cc.PixelIdxList);
        [~, idx] = max(numPixels);
        props = regionprops(cc);
        centroid = props(idx).Centroid;
        boundBox = props(idx).BoundingBox;
        
        M = getappdata(hfig,'M');
        dc = centroid - GetCenterPos(M(1).pos);
       % M(1).pos(:,1) = M(1).pos(:,1) + dc(1);
        %M(1).pos(:,2) = M(1).pos(:,2) + dc(2);
        
        % picking left and top? side
        dx = (2*boundBox(1) - M(1).pos(1,1) - M(1).pos(2,1))/2.0;
        dy = (2*boundBox(2) - M(1).pos(4,2) - M(1).pos(3,2))/2.0;

        M(1).pos(:,1) = M(1).pos(:,1) + dx;
        M(1).pos(:,2) = M(1).pos(:,2) + dy;
        setappdata(hfig,'M',M);
    end
end

%% find slot - JMS's linescan algorithm



%% draw mask
DrawNewMask(hfig);

end

function LoadPreviousImage(hfig)
i_im = getappdata(hfig,'i_im');
if i_im > 1
    i_im = i_im-1;
    LoadImage(hfig,i_im);
else
    msgbox('reached first image');
end
end

function LoadNextImage(hfig)
global h_i_im;
i_im = getappdata(hfig,'i_im');
numFiles = getappdata(hfig,'numFiles');
if i_im < numFiles
    i_im = i_im+1;
    LoadImage(hfig,i_im);    
    % update GUI
    h_i_im.String = num2str(i_im);
else
    msgbox('reached last image');
end
end

function masktypeID = ToggleSelectedMask(hfig)
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');

% save current pos of old mask
masktypeID_old = getappdata(hfig,'masktypeID');
M(masktypeID_old).pos = getPosition(hpoly(masktypeID_old));
delete(hpoly(masktypeID_old));

% toggle masktypeID
if masktypeID_old==1
    masktypeID = 2;    
elseif masktypeID_old==2
    masktypeID = 1;
end
setappdata(hfig,'masktypeID',masktypeID);
% redundant?
M(1).isselected = 0;
M(2).isselected = 0;
M(masktypeID).isselected = 1;

% draw new mask
hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
setColor(hpoly(masktypeID),[1,0,0]);

% save
setappdata(hfig,'M',M);
setappdata(hfig,'hpoly',hpoly);
end

function RotateMask(hfig,rotationAngle,masktypeID)
S = getappdata(hfig,'S');
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');

% record rotation angle for this section
if masktypeID == 1
    S.slot.rotation = S.slot.rotation + rotationAngle;
elseif masktypeID == 2
    S.section.rotation = S.section.rotation + rotationAngle;
end

pos = getPosition(hpoly(masktypeID));
center = GetCenterPos(pos);
poscenter = repmat(center,size(pos,1),1);
rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
pos2 = (pos-poscenter) * rotationArray + poscenter;
%     hpoly_section = impoly(h_ax, pos2);
setConstrainedPosition(hpoly(masktypeID),pos2);
M(masktypeID).pos = pos2;

% save
setappdata(hfig,'S',S);
setappdata(hfig,'M',M);
setappdata(hfig,'hpoly',hpoly);
end

function TranslateMask(hfig,translationArray,masktypeID)
S = getappdata(hfig,'S');
M = getappdata(hfig,'M');
hpoly = getappdata(hfig,'hpoly');

% % record translation for this section
% if masktypeID == 1
%     S.slot.translation = S.slot.translation + translationArray;
% elseif masktypeID == 2
%     S.section.translation = S.section.translation + translationArray;
% end

pos = getPosition(hpoly(masktypeID));
pos2 = pos;
pos2(:,1) = pos2(:,1)+translationArray(1);
pos2(:,2) = pos2(:,2)+translationArray(2);
setConstrainedPosition(hpoly(masktypeID),pos2);
M(masktypeID).pos = pos2;

% save
setappdata(hfig,'S',S);
setappdata(hfig,'M',M);
setappdata(hfig,'hpoly',hpoly);
end

function center = GetCenterPos(pos)
center = zeros(1,2);
center(1) = mean(pos(:,1));%(max(pos(:,1))-min(pos(:,1)))/2+min(pos(:,1));
center(2) = mean(pos(:,2));%(max(pos(:,2))-min(pos(:,2)))/2+min(pos(:,2));
end

function SetCenterPos(hfig, center, maskTypeID)
    hpoly = getappdata(hfig,'hpoly');
    pos = getPosition(hpoly(maskTypeID));
    c = GetCenterPos(pos);
    TranslateMask(hfig, center - c, maskTypeID)
end

function DrawNewMask(hfig)
M = getappdata(hfig,'M');
% hpoly = getappdata(hfig,'hpoly');

% % reset to slot
% masktypeID = 1;
% setappdata(hfig,'masktypeID',masktypeID);
% 
% % draw
% hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
% M(masktypeID).isselected = 1;
% setColor(hpoly(masktypeID),[1,0,0]);

masktypeID = 2;
setappdata(hfig,'masktypeID',masktypeID);

% draw
hpoly(1) = impoly(gca, M(1).pos);
delete(hpoly(1));
hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
M(masktypeID).isselected = 1;
setColor(hpoly(masktypeID),[1,0,0]);

% masktypeID = 2;
% 
% hpoly(masktypeID) = impoly(gca, M(masktypeID).pos);
% M(masktypeID).isselected = 0;
% setColor(hpoly(masktypeID),[0.7,0.7,0.7]);

setappdata(hfig,'hpoly',hpoly);
end

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

function LoadNewMask(hfig,slot_mask_file,section_mask_file)
%S = getappdata(hfig,'S');

pos_slot_init = dlmread(slot_mask_file,' ',1,0);
pos_section_init = dlmread(section_mask_file,' ',1,0);

% init mask struct
M = [];

masktypeID = 1;
M(masktypeID).pos_init = pos_slot_init;

masktypeID = 2;
M(masktypeID).pos_init = pos_section_init;

pos_slot = pos_slot_init;
pos_section = pos_section_init;
%pos_slot = S.slot.vertices;
%pos_section = S.section.vertices;
%[pos_slot,pos_section] = ReconstitutePos(S,M); 
% NB: this reconstitution is not correct for newly created masks, 
% but approximately right assuming that the new mask is similar to 
% the old one (e.g. minor shape adjustment).
M(1).pos = pos_slot;
M(2).pos = pos_section;

setappdata(hfig,'M',M);
end

function fig = getParentFigure(fig)
% if the object is a figure or figure descendent, return the figure. Otherwise return [].
while ~isempty(fig) && ~strcmp('figure', get(fig,'type'))
    fig = get(fig,'parent');
end
end
