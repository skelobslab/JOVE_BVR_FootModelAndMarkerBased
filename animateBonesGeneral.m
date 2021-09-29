% animate a trial
clear
clc
% Select all the necessary directories and the bones to animate

uiwait(msgbox('Please look at the header of the following file explorer boxes to know which folder to select.','Information','modal'))

% choose the subject directory
[subjectDir] = uigetdir('E:\AutoscoperTrainingPackage\Data\','Select SUBJECT directory');
if subjectDir == 0
    return
end
subjectDir = fullfile(subjectDir,filesep);


% choose the trial directory
[trialDir] = uigetdir(subjectDir,'Select TRIAL directory');
if trialDir == 0
    return
end
trialDir = fullfile(trialDir,filesep);


% choose the animation directory

[animDir] = uigetdir(trialDir,'Select ANIMATION directory');
if animDir == 0
    return
end
animDir = fullfile(animDir,filesep);
%% select the bones to animate
[bone_list,ivDir] = uigetfile([subjectDir '\Models\*.iv'],'Select the BONES','Multiselect','on');
if ischar(bone_list)
    bone_list = cellstr(bone_list);
end
%% get the files to animate 
traDir = fullfile(trialDir,'Autoscoper',filesep);
traFiles = dir([traDir, '*.tra']);


% get the name of the trial and the bone name
tr_loc = strsplit(trialDir,filesep);
trialName = tr_loc{end-1}; % the trial name

% get the subject number
nm_loc = strsplit(subjectDir,filesep);
name_temp = nm_loc{end};
name_temp = strsplit(name_temp,'_');
subjectName = name_temp{1}; % subject name

% the number of bones to animate
nbones = length(bone_list);
bonesCell = [];
for b = 1:nbones % for each bone
    file_spl = strsplit(bone_list{b},'_');
    boneout = 0; st = 0;
    while boneout == 0 || st > length(file_spl) % while the bone hasn't been found, or the # of split parts of the file is exceeded
        st = st + 1;
        boneout = bonecodeFT(file_spl{st}); % if you have other bones, add a line in this code to assign a numeric value
        
    end
    
    bonesCell{b} = file_spl{st};% list the bone strings in a cell array
    file_ind = findInStruct(traFiles,'name',bonesCell{b});% find the tracking file with that bone code
    
    % look for the tracking file with "interp" at the end to bias towards
    % animating with as many frames as possible. Otherwise, choose the
    % available tracking file for that bone
    if length(file_ind) > 1 
        for f = 1:length(file_ind)
        if contains(traFiles(file_ind(f)).name,'interp')
            file_ind = file_ind(f);
            break
        end
        end
    end
    if isempty(file_ind)
        error('Bone (%s) selected does not have a .tra Autoscoper file.',bone_list{b})
    end
    % save the reference files and tracking files in the same index as each
    % bone
    traFilesCell{b} = traFiles(file_ind).name;
end
        
        
%% animate the files

% create the rigidiv directory; this is where all the bones will be linked
rigidivDir = fullfile(animDir,'rigidiv',filesep);

if exist(rigidivDir,'dir')==0;  mkdir(rigidivDir);  end


first_fr = 100000;
end_fr = 0;


for bn = 1:nbones
    
    % load the .tra files
    
    Tauto = dlmread(fullfile(traDir,traFilesCell{bn}));
    nanind = isnan(Tauto);
    Tauto(nanind) = 1; % wristvisualizer needs 1's where there is no data
    Tanim.(bonesCell{bn}) = convertRotation(Tauto,'autoscoper','4x4xn');
    
    nfrs = size(Tauto,1);
    % find where there's data in the autoscoped .tra file
    ttt = diff(Tauto);
    frs = find(abs(ttt(:,1)) > 0);
    
    % set the first and last frame to be as wide as the bone with the most
    % tracked data
    if frs(1)-1 < first_fr
        
        first_fr = frs(1)-1;
        if first_fr == 0
            first_fr = 1;
        end
    end
    if frs(end)+1 > end_fr
        
            end_fr = frs(end)+1;
        if end_fr >= nfrs
            end_fr = nfrs;
        end
    end
    
    
    % make the linked IV files
    ivstring = createInventorHeader();
    % make the linked iv file
    ivstring = [ivstring createInventorLink([ivDir bone_list{bn}],eye(3,3),zeros(3,1),[0.7 0.7 0.7],0.5)];
    
    fid = fopen(fullfile(rigidivDir,[bonesCell{bn} '.iv']),'w');
    fprintf(fid,ivstring);
    fclose(fid);
    
    
end

for bn = 1:nbones
    % write the RTp files to animate the transforms
    write_RTp(bonesCell{bn} , Tanim.(bonesCell{bn})(:,:,first_fr:end_fr) , animDir)
end

% write the pos file to run the animation
pos_text = write_pos(bonesCell,animDir,trialName);

filename = fullfile(animDir, [trialName '.pos']);

fid = fopen(filename,'w'); % open the file to write
fprintf(fid,pos_text);
fclose(fid);

fprintf('Animation created successfully in %s \n', filename)

%% write the bone transform file

boneT_dir = fullfile(trialDir,'BoneTransforms',filesep);
if exist(boneT_dir,'dir') == 0
    mkdir(boneT_dir);
end

% save the transforms in a nice MAT file
T = Tanim;
boneTfile = fullfile(boneT_dir,[trialName '_transforms.mat']);
save(boneTfile,'T')


fprintf('Bone transform file created successfully in %s \n', boneTfile)
