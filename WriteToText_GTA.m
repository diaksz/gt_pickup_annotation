function WriteToText_GTA(secID,S,outputPath)
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

% write data
fprintf(fileID,'row 1: slot (x,y,theta)\n');
fprintf(fileID,'row 2: section (x,y,theta)\n');
fprintf(fileID,'row 3: is_problematic,is_verified\n');
[~,name,ext] = fileparts(S.slot_mask_file);
fprintf(fileID,['slot mask file: ',name,ext,'\n']);
[~,name,ext] = fileparts(S.section_mask_file);
fprintf(fileID,['section mask file: ',name,ext,'\n']);

formatSpec = '%4.2f %4.2f %4.2f\n';
fprintf(fileID,formatSpec,S.slot.translation(1),S.slot.translation(2),S.slot.rotation);

% fprintf(fileID,'section mask\n');
formatSpec = '%4.2f %4.2f %4.2f\n';
% formatSpec = '[section] x: %4.2f; y: %4.2f; theta: %4.2f \n';
fprintf(fileID,formatSpec,S.section.translation(1),S.section.translation(2),S.section.rotation);

fprintf(fileID,'%d %d\n',S.is_problematic,S.is_verified);
% fprintf(fileID,'is_verified = %d\n',S.is_verified);


% close file
fclose(fileID);

end