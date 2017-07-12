% make movie

%% load mask
% master path
masterPath = 'C:\Users\akuan\Dropbox (HMS)\htem_team\projects\PPC_project\stainingImages';

% saved mask templates for slot and section, respectively, in txt
slot_mask_file = [masterPath '\masks\' 'slot_mask_sect0010_170705.txt'];
section_mask_file = [masterPath '\masks\' 'section_mask_sec0010_170705.txt'];

% image folder


%% parse dir
imPath = [masterPath '\ppc0_links']; % contains images of individual sections
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
            %         disp(['file ''',a,''' does not match expected file name format']);
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

%% load annotated txt file
outputPath = [masterPath '\annotations']; % saves annotated relative positions to txt, for each individual section
%S = ScanText_GTA(secID,outputPath);

%% load images
i_count = 236;
secID = List.sectionIDs(i_count);
im_raw = imread(fullfile(imPath,List.filenames{i_count}));
figure;imshow(histeq(im_raw(:,:,3),20),jet(255));

%% load masks




%%

% pos_section_init = dlmread(section_mask_file,' ',1,0);
% pos = pos_section_init;
pos_slot = M(1).pos_init; %dlmread(slot_mask_file,' ',1,0);
pos_section = M(2).pos; %dlmread(section_mask_file,' ',1,0);

hp = impoly(gca,pos_slot);
slotmask = createMask(hp);
%figure;imagesc(slotmask);

hp2 = impoly(gca,pos_section);
sectionmask = createMask(hp2);
%figure;imagesc(sectionmask);

A = imread(fullfile(imPath,List.filenames{i_count}));
A1 = imfuse(sectionmask,A);
figure;imagesc(A1);

%% Set up figure

scrn = get(0,'Screensize');
hfig1 = figure('Position',[scrn(3)*0 scrn(4)*0 scrn(3)*1 scrn(4)*1],...% [50 100 1700 900]
    'Name','GridTapeAlign','DeleteFcn',@closefigure_Callback,...
    'KeyPressFcn',@KeyPressCallback,...
    'WindowButtonDownFcn',@WindowButtonDownCallback,...
    'ToolBar', 'none'); % 'MenuBar', 'none'
hold off; axis off

% init GUI drawing axes
ax_pos = [0.1, 0.1, 0.8, 0.7];
% setappdata(hfig,'ax_pos',ax_pos);
figure(hfig1);
h_ax = axes('Position',ax_pos);
axis image
%% loop (movie not slot aligned for now


clear F;
range_im = 432:436; % hard coded for now
for i_count = 1:length(range_im);
    tic
    secID = List.sectionIDs(range_im(i_count));
    im_raw = imread(fullfile(imPath,List.filenames{range_im(i_count)}));
    figure(hfig1);
    %imagesc(im_raw);
    
    S = ScanText_GTA(secID,outputPath);
    pos_slot = S.slot.vertices;
    pos_section = S.section.vertices;
    %{
    M = LoadNewMask(slot_mask_file,section_mask_file,S);
    pos_slot = M(1).pos; %dlmread(slot_mask_file,' ',1,0);
    pos_section = M(2).pos; %dlmread(section_mask_file,' ',1,0);
    %}
   
    
    A = imread(fullfile(imPath,List.filenames{range_im(i_count)}));
    
    % Preprocess image to make easier to see edges
    left_crop = 250;
    right_crop = 1280;
    top_crop = 250;
    bottom_crop = 750;
    channel = 3; % blue channel seems to be the most informative
    num_levels = 20; % number of levels for histogram equalization
    A2 = histeq(im_raw(top_crop:bottom_crop,left_crop:right_crop,3),20);
    A1 = A2;
    %A1 = imfuse(sectionmask,A2,'blend');
  

    imagesc(A1); axis equal; axis off; hold on;
    
    % plot section
    hp = impoly(gca,pos_slot);
    %slotmask = createMask(hp);
    %figure;imagesc(slotmask);
    
    %hp2 = impoly(gca,pos_section);
    %sectionmask = createMask(hp2);
    %figure;imagesc(sectionmask);
    section_outline = vertcat(pos_section, pos_section(1,:));
    plot(section_outline(:,1),section_outline(:,2),'w-','Linewidth',2)
    title(['sect ' num2str(secID)]);
    
    %{
    rotationAngle = S.slot.rotation;
    B0 = imrotate(A1,-rotationAngle); % this is a rough approx... not the exact inverse of the encoding
    
    translation = S.slot.translation;
    B = imtranslate(B0,-translation);
        
    C = B;%imfuse(slotmask,B,'blend');
       
    imagesc(B)
    %}
    F(i_count) = getframe;%im2frame(C); 
    toc
end
%%
figure
nloops = 3;
fps = 5;
movie(F,nloops,fps);
%% Write to animated gif
filename = 'testAnimated.gif'; % Specify the output file name
for idx = 1:length(range_im)
    [A,map] = rgb2ind(F(idx).cdata,256);
    if idx == 1
        imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',.2);
    else
        imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',.2);
    end
end

%% write video to file
myVideo = VideoWriter('myfile.avi');
myVideo.FrameRate = 5;  % Default 30
myVideo.Quality = 50;    % Default 75
open(myVideo);
writeVideo(myVideo, F);
close(myVideo);

