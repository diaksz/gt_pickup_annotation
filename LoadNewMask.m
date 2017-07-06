function M = LoadNewMask(slot_mask_file,section_mask_file,S)
%S = getappdata(hfig,'S');

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
%[pos_slot,pos_section] = ReconstitutePos(S,M); 
% NB: this reconstitution is not correct for newly created masks, 
% but approximately right assuming that the new mask is similar to 
% the old one (e.g. minor shape adjustment).
M(1).pos = pos_slot;
M(2).pos = pos_section;

%setappdata(hfig,'M',M);
end