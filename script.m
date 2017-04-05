% make movie

%% load mask
slot_mask_file = 'C:\Users\Xiu\Dropbox (Personal)\EM_ppc\masks\slot_mask.txt';
section_mask_file = 'C:\Users\Xiu\Dropbox (Personal)\EM_ppc\masks\section_mask.txt';

%% parse dir
imPath = 'C:\Users\Xiu\Dropbox (Personal)\EM_ppc\ppc0_links';
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
outputPath = 'C:\Users\Xiu\Dropbox (Personal)\EM_ppc\output';
S = ScanText_GTA(secID,outputPath);

%% load images
i_count = 2;
secID = List.sectionIDs(i_count);
im_raw = imread(fullfile(imPath,List.filenames{i_count}));
figure;imagesc(im_raw);

% pos_section_init = dlmread(section_mask_file,' ',1,0);
% pos = pos_section_init;
pos_slot_init = dlmread(slot_mask_file,' ',1,0);

hp = impoly(gca,pos_slot_init);
mask = createMask(hp);
figure;imagesc(mask)

%% loop
figure;
range_im = 2:11;
for i_count = 1:length(range_im);
    secID = List.sectionIDs(range_im(i_count));
    S = ScanText_GTA(secID,outputPath);

    A = imread(fullfile(imPath,List.filenames{range_im(i_count)}));
    rotationAngle = S.slot.relangle;
    B0 = imrotate(A,-rotationAngle); % this is a rough approx... not the exact inverse of the encoding
    
    translation = S.slot.relpos;
    B = imtranslate(B0,-translation);
    
    C = imfuse(mask,B);

    imagesc(C)
    F(i_count) = getframe;%im2frame(C);
end
%%
figure
nloops = 3;
fps = 5;
movie(F,nloops,fps);

%% write video to file
myVideo = VideoWriter('myfile.avi');
myVideo.FrameRate = 5;  % Default 30
myVideo.Quality = 50;    % Default 75
open(myVideo);
writeVideo(myVideo, F);
close(myVideo);


%% encoding code:
% M = getappdata(hfig,'M');
%     % slot
%      masktypeID = 1;
%     % rotate
%     rotationAngle = S.slot.relangle;
%     pos = M(masktypeID).pos_init;
%     center = GetCenterPos(pos);
%     poscenter = repmat(center,size(pos,1),1);
%     rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
%     pos2 = (pos-poscenter) * rotationArray + poscenter;
%     
%     % translate
%     translationArray = S.slot.relpos;
%     pos2(:,1) = pos2(:,1)+translationArray(1);
%     pos2(:,2) = pos2(:,2)+translationArray(2);
% 
%     M(masktypeID).pos = pos2;
%     
%     % section
%     masktypeID = 2;
%     % rotate
%     rotationAngle = S.section.relangle;
%     pos = M(masktypeID).pos_init;
%     center = GetCenterPos(pos);
%     poscenter = repmat(center,size(pos,1),1);
%     rotationArray = [cos(rotationAngle), -sin(rotationAngle); sin(rotationAngle), cos(rotationAngle)];
%     pos2 = (pos-poscenter) * rotationArray + poscenter;
%     
%     % translate
%     translationArray = S.section.relpos;
%     pos2(:,1) = pos2(:,1)+translationArray(1);
%     pos2(:,2) = pos2(:,2)+translationArray(2);
% 
%     M(masktypeID).pos = pos2;