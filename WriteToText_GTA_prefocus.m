function WriteToText_GTA(secID,S,M,outputPath)
% S.slot.translation = [0,0];
% S.slot.rotation = 0;
% S.section.translation = [0,0];
% S.section.rotation = 0;
% S.is_problematic = 0;
% S.is_verified = 0;
%%
% open file
f = fullfile(outputPath,[num2str(secID),'.txt']);
% f = fullfile(outputPath,[num2str(secID,'%04d'),'.txt']);
fileID = fopen(f,'wt');

fprintf(fileID,'FLAGS\n');
fprintf(fileID,'is_problematic,is_verified\n');
fprintf(fileID,'%d %d\n',S.is_problematic,S.is_verified);
% fprintf(fileID,'is_verified = %d\n',S.is_verified);
fprintf(fileID,'SGALF\n');
fprintf(fileID,'\n');

% write data
fprintf(fileID,'SLOT\n');

for i = 1:size(M(1).pos,1)
    formatSpec = '%4.2f %4.2f\n';
    fprintf(fileID,formatSpec,M(1).pos(i,1),M(1).pos(i,2));
end
fprintf(fileID,'TOLS\n');
fprintf(fileID,'\n');

fprintf(fileID,'SLOTCOM(x,y,theta):\n');
formatSpec = '%4.2f %4.2f %4.2f\n';
fprintf(fileID,formatSpec,S.slot.translation(1),S.slot.translation(2),S.slot.rotation);
fprintf(fileID,'\n');

fprintf(fileID,'SECTION\n');
for i = 1:size(M(2).pos,1)
    formatSpec = '%4.2f %4.2f\n';
    fprintf(fileID,formatSpec,M(2).pos(i,1),M(2).pos(i,2));
end
fprintf(fileID,'NOITCES\n');
fprintf(fileID,'\n');



fprintf(fileID,'SECTIONCOM(x,y,theta):\n');
% fprintf(fileID,'section mask\n');
formatSpec = '%4.2f %4.2f %4.2f\n';
%formatSpec = '[section] x: %4.2f; y: %4.2f; theta: %4.2f \n';
fprintf(fileID,formatSpec,S.section.translation(1),S.section.translation(2),S.section.rotation);
fprintf(fileID,'\n');

[~,name,ext] = fileparts(S.slot_mask_file);
fprintf(fileID,['slot mask file: ',name,ext,'\n']);
[~,name,ext] = fileparts(S.section_mask_file);
fprintf(fileID,['section mask file: ',name,ext,'\n']);
fprintf(fileID,'\n');
% close file
fclose(fileID);

end