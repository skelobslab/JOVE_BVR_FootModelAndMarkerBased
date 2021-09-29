% animate a trial
close all
clear
clc
% Select all the necessary directories and the bones to animate

uiwait(msgbox('Please look at the header of the following file explorer boxes to know which folder to select.','Information','modal'))

% the rotation and translation thresholds 
rot_thresh = 2; % deg /rotation
trans_thresh = 1; % mm /translation

% choose the subject directory
[subjectDir] = uigetdir([],'Select SUBJECT directory');
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

refDir = fullfile(trialDir,'Reference',filesep);
%% select the bones to animate
[bone_list,ivDir] = uigetfile([subjectDir '\Models\IV\*.iv'],'Select the BONES','Multiselect','on');
if ischar(bone_list)
    bone_list = cellstr(bone_list);
end
%% get the files to animate 
traDir = fullfile(trialDir,'Autoscoper',filesep);
traFiles = dir([traDir, '*.tra']);
refTraFiles = dir([refDir, '*.tra']);

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
    while boneout == 0 || st > length(file_spl) % while the bone hasn't been identified, or the # of split parts of the file is exceeded
        st = st + 1;
        boneout = bonecodeFT(file_spl{st}); % if you have other bones, add a line in this code to assign a numeric value
    end
    
    bonesCell{b} = file_spl{st}; % list the bone strings in a cell array
    file_ind = findInStruct(traFiles,'name',bonesCell{b}); % find the tracking file with that bone code
    fileRef_ind = findInStruct(refTraFiles,'name',bonesCell{b}); % find the reference tracking file with that bone code
    
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
    if isempty(file_ind) % error catch
        error('Bone (%s) selected does not have a .tra Autoscoper file.',bone_list{b})
    end
    
    if length(fileRef_ind) > 1
        for f = 1:length(fileRef_ind)
            if contains(refTraFiles(fileRef_ind(f)).name,'Unfilt')
                fileRef_ind = fileRef_ind(f);
                break
            end
        end
    end
    if isempty(fileRef_ind)
        error('Bone (%s) selected does not have a reference .tra Autoscoper file.',bone_list{b})
    end
    % save the reference files and tracking files in the same index as each
    % bone
    refTraFilesCell{b} = refTraFiles(fileRef_ind).name;
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
    
    frms_trkd = find(nanind(:,1)==0);
    
    % load the references
    TRauto = dlmread(fullfile(refDir,refTraFilesCell{bn}));
    nanind = isnan(TRauto);
    TRauto(nanind) = 1;% wristvisualizer needs 1's where there is no data
    TRanim.(bonesCell{bn}) = convertRotation(TRauto,'autoscoper','4x4xn');
    
    % create the good and the bad animation bones transforms
    bad_fr.(bonesCell{bn}) = [];
    good_fr.(bonesCell{bn}) = [];
    TGanim.(bonesCell{bn}) =  TRanim.(bonesCell{bn});
    TBanim.(bonesCell{bn}) =  TRanim.(bonesCell{bn});
   for fr = frms_trkd' % for each frame
%        determine how close the bone is to the reference
       T = invTranspose(TRanim.(bonesCell{bn})(:,:,fr)) * Tanim.(bonesCell{bn})(:,:,fr);
       qual.(bonesCell{bn})(fr,:) = convertRotation( T, '4x4xn','helical'); % measure the helical axis difference between the beaded transform and autoscoped transform
       phi = qual.(bonesCell{bn})(fr,1); % the angle 
       trans = abs(qual.(bonesCell{bn})(fr,5)); % the translation
       metric.(bonesCell{bn})(fr,:) = [fr, phi  , trans]; % has the frame, the angle and the translation
       if phi > rot_thresh || trans > trans_thresh % the limits of agreement
           % error, remove the good bone
           TGanim.(bonesCell{bn})(:,:,fr) =  ones(4,4);
           bad_fr.(bonesCell{bn}) = [bad_fr.(bonesCell{bn}),fr];
       else % good, remove the bad bone
           good_fr.(bonesCell{bn}) = [good_fr.(bonesCell{bn}),fr];
           TBanim.(bonesCell{bn})(:,:,fr) =   ones(4,4);
       end
   end
    
    % find where there's data in the autoscoped .tra file
    ttt = diff(Tauto);
    frs = find(ttt(:,1) > 0);
    % set the first and last frame to be as wide as the bone with the most
    % tracked data
    if frs(1)-1 < first_fr
    first_fr = frs(1);
    end
    if frs(end)+1 > end_fr
    end_fr = frs(end);
    end
    
    
    % make the linked IV files
    ivstring = createInventorHeader();
    % make the linked iv file
    ivstring = [ivstring createInventorLink([ivDir bone_list{bn}],eye(3,3),zeros(3,1),[0.7 0.7 0.7],0.2)];
    
    fid = fopen(fullfile(rigidivDir,[bonesCell{bn} '.iv']),'w');
    fprintf(fid,ivstring);
    fclose(fid);
    
    
    % create the "bad" bone
    ivstring = createInventorHeader();
    bonesCellRefB{bn} = [bonesCell{bn} '_RefB'];
    
    bonesRef{bn} = [bone_list{bn}(1:end-3) '_RefB.iv' ];
    % the reference bone
    ivstring = [ivstring createInventorLink(fullfile(ivDir, bone_list{bn}),eye(3,3),zeros(3,1),[1 0 0],0.8)]; % in red
        fid = fopen(fullfile(rigidivDir,[bonesCellRefB{bn} '.iv'] ),'w');
    fprintf(fid,ivstring);
    fclose(fid);
    
    % create the "good bone" 
    ivstring = createInventorHeader();
    bonesCellRefG{bn} = [bonesCell{bn} '_RefG'];
    
    bonesRef{bn} = [bone_list{bn}(1:end-3) '_RefG.iv' ];
    % the reference bone
    ivstring = [ivstring createInventorLink(fullfile(ivDir, bone_list{bn}),eye(3,3),zeros(3,1),[0 1 0],0.8)]; % in green
        fid = fopen(fullfile(rigidivDir,[bonesCellRefG{bn} '.iv'] ),'w');
    fprintf(fid,ivstring);
    fclose(fid);
    
end


for bn = 1:nbones
    % write the RTp files to animate the transforms
    write_RTp(bonesCell{bn} , Tanim.(bonesCell{bn})(:,:,first_fr:end_fr) , animDir)
    write_RTp(bonesCellRefB{bn}  , TBanim.(bonesCell{bn})(:,:,first_fr:end_fr) , animDir)
    write_RTp(bonesCellRefG{bn}  , TGanim.(bonesCell{bn})(:,:,first_fr:end_fr) , animDir)
end

% write the pos file to run the animation
pos_text = write_pos([bonesCell , bonesCellRefB, bonesCellRefG ],animDir,trialName);

filename = fullfile(animDir, [trialName '.pos']);

fid = fopen(filename,'w'); % open the file to write
fprintf(fid,pos_text);
fclose(fid);

fprintf('Animation created successfully in %s \n', filename)




%% visualization of frames with rotation/translation errors
close all
valst = [];
valsr = [];
cmap = parula(10); % get a colormap

for bn = 1:nbones
    str = [];
    for i = 1:length(bad_fr.(bonesCell{bn}))
        str = [str num2str(bad_fr.(bonesCell{bn})(i)-1), ', '];
    end
    fprintf('Frames for %s that need improved tracking are: %s\n',(bonesCell{bn}),str(1:end-2))
    
    i0= metric.(bonesCell{bn})(:,1); % all the frames are in the first column
    lims = [min(i0)-1 max(i0)+5]; % set the limits of visualization
    
    figure(1);
    subplot(nbones,1,bn)
    
    hold on;
    hr(1) = plot(metric.(bonesCell{bn})(i0,1)-1,metric.(bonesCell{bn})(i0,2),'o','color',cmap(2,:)); % plot the rotation error relative to the autoscoper frames (0 based, hence -1)
    hr(2) = plot(lims,[rot_thresh rot_thresh],'color',cmap(2,:));   % draw the threshold line
    

    plot(lims(2),mean(metric.(bonesCell{bn})(i0,2)),'o','color',cmap(2,:))
    errorbar(lims(2),mean(metric.(bonesCell{bn})(i0,2)),std(metric.(bonesCell{bn})(i0,2)),'color',cmap(2,:))
    
    hrl = legend(hr,{'Rotation error','Rotation Threshold'});
    hrl.Location = 'northwest';
    xlim(lims)
    ylabel('Rotation [^o]')
     ylim([0 5])
     
    xlabel('Frame')
    title(bonesCell{bn})
    
    
    figure(2)
    subplot(nbones,1,bn)
    hold on
    ht(1) = plot(metric.(bonesCell{bn})(i0,1)-1,metric.(bonesCell{bn})(i0,3),'x','color',cmap(6,:));
    ht(2) = plot(lims,[trans_thresh trans_thresh],'color',cmap(6,:));
    
    plot(lims(2),mean(metric.(bonesCell{bn})(i0,3)),'x','color',cmap(6,:))
    errorbar(lims(2),mean(metric.(bonesCell{bn})(i0,3)),std(metric.(bonesCell{bn})(i0,3)),'color',cmap(6,:))
    
    
    xlim(lims)
    ylim([0 5])
    ylabel('Translation [mm]')
    
    
    xlabel('Frame')
    title(bonesCell{bn})
    
    
    htl = legend(ht,{'Translation Error','Translation Threshold'});
    htl.Location = 'northwest';
    
end
