% animate a trial
% close all
clear
clc

% Select all the necessary directories and the bones to animate

uiwait(msgbox('Please look at the header of the following file explorer boxes to know which folder to select.','Information','modal'))

% the rotation and translation thresholds 
rot_thresh = 2; % deg /rotation
trans_thresh = 1; % mm /translation

autoPkgDir = uigetdir([],'Select JOVE_BVR_Foot_ModelAndMarkerBased directory');
if autoPkgDir  == 0
    return
end
autoPkgDir  = fullfile(autoPkgDir ,filesep);

subjectDir = fullfile(autoPkgDir,'\Data\SOL001A\');

% choose the trial directory
[trialDir] = uigetdir(subjectDir,'Select TRIAL directory');
if trialDir == 0
    return
end
trialDir = fullfile(trialDir,filesep);

%% choose the operator's tracking directory + files

[traFiles,traDir] = uigetfile([trialDir,'*.tra'],'Select OPERATOR''S TRACKING FILES directory','Multiselect','on');
if traDir == 0
    return
end
if ischar(traFiles)
    traFiles = cellstr(traFiles);
end
traDir = fullfile(traDir,filesep);

% where the beaded references are

refDir = fullfile(trialDir,'Reference',filesep);
%% select the bones 
[bone_list,ivDir] = uigetfile([subjectDir '\Models\IV\*.iv'],'Select the BONES','Multiselect','on');
if ischar(bone_list)
    bone_list = cellstr(bone_list);
end
%% get the tracking files from the new operator and the beaded reference poses

refTraFiles = dir([refDir, '*.tra']);
nm_loc = strsplit(subjectDir,filesep);
bone_temp = nm_loc{end};
bone_temp = strsplit(bone_temp,'_');
subjectName = bone_temp{1};

nbones = length(bone_list);
bonesCell = [];

for b = 1:nbones
    file_spl = strsplit(bone_list{b},'_');
    boneout = 0; st = 0;
    while boneout == 0 || st > length(file_spl) % while the bone hasn't been found, or the # of split parts of the file is exceeded
        st = st + 1;
        boneout = bonecodeFT(file_spl{st});
        
    end
    
    bonesCell{b} = file_spl{st};
    file_ind = find(contains(traFiles,bonesCell{b})); 
    fileRef_ind = findInStruct(refTraFiles,'name',bonesCell{b});
    
    if length(file_ind) > 1 
        for f = 1:length(file_ind)
        if contains(traFiles{file_ind(f)},'interp')
            file_ind = file_ind(f);
            break
        end
        end
    end
    if isempty(file_ind)
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
    
    refTraFilesCell{b} = refTraFiles(fileRef_ind).name;
    traFilesCell{b} = traFiles{file_ind};
end
        
        
%% measure the differences in poses using the helical axis



for bn = 1:nbones
    
    % load the .tra files
    
    Tauto = dlmread(fullfile(traDir,traFilesCell{bn}));
    Tanim.(bonesCell{bn}) = convertRotation(Tauto,'autoscoper','4x4xn');
    
    TRauto = dlmread(fullfile(refDir,refTraFilesCell{bn}));
    TRanim.(bonesCell{bn}) = convertRotation(TRauto,'autoscoper','4x4xn');
    
   
    
   for fr = 1:size(Tauto,1) % determine how close the bone is to the reference
       T = invTranspose(TRanim.(bonesCell{bn})(:,:,fr)) * Tanim.(bonesCell{bn})(:,:,fr);
       qual.(bonesCell{bn})(fr,:) = convertRotation( T, '4x4xn','helical');
       phi = qual.(bonesCell{bn})(fr,1);
       trans = abs(qual.(bonesCell{bn})(fr,5));
       metric.(bonesCell{bn})(fr,:) =real([fr, phi  , trans]);

   end

end



%% visualization of frames with rotation/translation errors
% close all

cmap = parula(10);

for bn = 1:nbones
    
    i0= metric.(bonesCell{bn})(:,1); % all the frames are in the first column
    lims = [min(i0)-1 max(i0)+5]; % set the limits of visualization
    
    % PLOT THE ROTATION ERROR
    figure(1);
    subplot(nbones,1,bn)
    
    hold on;
    hr(1) = plot(metric.(bonesCell{bn})(i0,1)-1,metric.(bonesCell{bn})(i0,2),'o','color',cmap(2,:));% plot the rotation error relative to the autoscoper frames (0 based, hence -1)
    hr(2) = plot(lims,[rot_thresh rot_thresh],'color',cmap(2,:));     % draw the threshold line
    

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
    ht(2) = plot(lims,[trans_thresh,trans_thresh],'color',cmap(6,:));
    
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

% get the folder in which to save the operator results
[filepath] = uigetdir(traDir,'SAVE operator results?');

if filepath~=0 % if a folder is selected, then save the translation and rotaion data
    for bn = 1:nbones
        T = table(metric.(bonesCell{bn})(i0,1),metric.(bonesCell{bn})(i0,2),metric.(bonesCell{bn})(i0,3),'VariableNames',{'Frame','Rotation Error [deg]','Translation Error [mm]'});
        writetable(T,fullfile(filepath,['results_' bonesCell{bn} '.csv']),'Delimiter',',');
        fprintf('Quality of pose estimation written to %s\n', fullfile(filepath,['results_' bonesCell{bn} '.csv']))
        
        
    end
end
