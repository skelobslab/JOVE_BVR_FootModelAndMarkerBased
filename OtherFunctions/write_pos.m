function pos_text = write_pos(bones,animFolder,filename)
% Write a posview file to be opened in wrist visualiser. Saves in the
% "animFolder" animFolderory
% L. Welte Dec 2017
% --INPUTS--
% bones         =       cell array with list of bones to be animated
% animFolder        =       animFolderory with the rigidiv folder and animate
%                       folder with the .rTP files
% filename      =       optional argument to select filename

nbones = length(bones);

%uncomment this when running it on linux
% ivdir = fullfile(animFolder,'rigidiv',filesep); % filesep adds an end slash
% animFolder = fullfile(animFolder,filesep); % make sure there's a file separator at the end

%when programming for windows:
animFolder2 = strrep(animFolder,'\','/');
ivdir = [animFolder2 '\n' 'rigidiv/']; 

if isempty(filename) % if no file is specified
    filename = fullfile(animFolder2,'animate.pos'); % give it default file name
elseif isempty(regexp(filename,'.pos')) % if the specified file doesn't have .pos at the end
    filename = fullfile(animFolder2,[filename '.pos']);
end

% write all of the text in the pos file to an array
pos_text = [ivdir '\n'];                    % IV animFolderory at the top
pos_text = [pos_text num2str(nbones) '\n']; % number of bones/objects to animate

for i = 1:nbones
    pos_text = [pos_text bones{i} '.iv' '\n'];    % list all the iv files
end

for i = 1:nbones
    pos_text = [pos_text animFolder2 bones{i} '_anim' '\n'];    % list all the animFolderories
end

% write the pos text to the file if there is no output specified
if nargout == 0
    fid = fopen(filename,'w'); % open the file to write
    fprintf(fid, pos_text);
    fclose(fid);
    
    disp(['Saved file : ' filename '. '])
    
end





