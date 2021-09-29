function write_RTp(bones,T,direct)
% Function to write RTp files for wrist visualizer

% -- INPUTS -- 
%
% writeRTp(filename,T,direct) <- for one object/bone to be animated
%
% bones         =       String of bone name / filename
% T             =       Transformation matrix [4x4]->[[R] [T]; 0 0 0 1] 
%                       Supports third dimension as the number of frames
%
% writeRTp(bones,T,direct)    <- for multiple bones/objects to be animated
%
% bones         =       Cell array with each bone name /object to be animated as
%                       a string
% T             =       Same as above, but is now a cell array where 
%                       each row is a different bone/object to be animated
%                       which corresponds with the same indices as bone.
% direct        =       directory with the rigidiv folder and animate
%                       folder with the .rTP files


if iscell(T) % input is a cell array with bone list
  
    nbones = length(bones);
    
    if nbones ~= length(T)
        error('Number of sets of transformations does not match number of bones.')
        return
    end
    
    for i = 1:nbones
        fullfilename{i} = fullfile(direct,[bones{i} '_anim.RTp']);
    end
    
    
else       % input is just a file
    nbones = 1;
    T = {T}; % convert T to a cell array
    if isempty(bones) % if no file is specified
        fullfilename{1} = fullfile(direct,'anim.RTp'); % give it default file name
    elseif isempty(regexp(bones,'.RTp')) % if the specified file doesn't have .RTp at the end
        fullfilename{1} = fullfile(direct,[bones '_anim.RTp']);
    else
        fullfilename{1} = fullfile(direct,bones);
    end
end




for i = 1:nbones
   rtp_text = getRTpText(T{i});
   fid = fopen(fullfilename{i},'w');
   fprintf(fid,rtp_text);
   fclose(fid);
end



end


function rtp_text = getRTpText(T)


nframes = size(T,3);
rtp_text = [num2str(nframes) '\n'];

for i = 1:nframes
    aRT = makeAnimRT(T(:,:,i));     % transform into the appropriate format
    for j = 1:4
        rtp_text = [rtp_text sprintf('%f\t',aRT(j,:)) '\n'];
    end
end


end




function AnimRT = makeAnimRT(RT)
% bring in a normal RT matrix [[R] [T]; 0 0 0 1] and move the translation
% to where the zeros are

AnimRT(1:3,1:3) = RT(1:3,1:3);
AnimRT(4,1:3) = RT(1:3,4)';

end