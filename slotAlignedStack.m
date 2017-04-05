% make movie

%% load mask
% master path
masterPath = 'C:\Users\akuan\Dropbox (HMS)\htem_team\projects\PPC_project\stainingImages';

% saved mask templates for slot and section, respectively, in txt
slot_mask_file = [masterPath '\masks\' '170404_slot_mask.txt'];
section_mask_file = [masterPath '\masks\' '170404_section_mask2.txt'];

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
i_count = 2494;
secID = List.sectionIDs(i_count);
im_raw = imread(fullfile(imPath,List.filenames{i_count}));
figure;imagesc(im_raw);


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

A = imread(fullfile(imPath,List.filenames{2494}));
A1 = imfuse(sectionmask,A);
figure;imagesc(A1);

%% update section translation and rotation


%% loop
figure; clear F;
range_im = 2475:2494; % hard coded for now
for i_count = 1:length(range_im);
    tic
    secID = List.sectionIDs(range_im(i_count));
    im_raw = imread(fullfile(imPath,List.filenames{range_im(i_count)}));
    imagesc(im_raw);
    
    S = ScanText_GTA(secID,outputPath);
    M = LoadNewMask(slot_mask_file,section_mask_file,S);
    pos_slot = M(1).pos; %dlmread(slot_mask_file,' ',1,0);
    pos_section = M(2).pos; %dlmread(section_mask_file,' ',1,0);
    
    hp = impoly(gca,pos_slot);
    slotmask = createMask(hp);
    %figure;imagesc(slotmask);
    
    hp2 = impoly(gca,pos_section);
    sectionmask = createMask(hp2);
    %figure;imagesc(sectionmask);
    
    A = imread(fullfile(imPath,List.filenames{range_im(i_count)}));
    A1 = imfuse(sectionmask,A,'blend');
    imagesc(A1); title(['sect ' num2str(secID)]);
    
    rotationAngle = S.slot.rotation;
    B0 = imrotate(A1,-rotationAngle); % this is a rough approx... not the exact inverse of the encoding
    
    translation = S.slot.translation;
    B = imtranslate(B0,-translation);
        
    C = B;%imfuse(slotmask,B,'blend');

    imagesc(C)
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

