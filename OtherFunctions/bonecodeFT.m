function boneout = bonecodeFT(bonein)
% This function returns the corresponding identifier for the carpal bones.
% If input is the bone number, output is the 3-letter bone name. If input
% is the full bone name, or 3-letter name, output is the bone number.

if ischar(bonein)
    bonein = lower(bonein);
end %if

switch bonein
    case 'tibia'
        boneout = 1;
    case 'fibula'
        boneout = 2;
    case 'talus'
        boneout = 3;
    case 'calcaneus'
        boneout = 4;
    case 'navicular'
        boneout = 5;
    case 'cuboid'
        boneout = 6;
    case 'medial cuneiform'
        boneout = 7;
    case 'intermediate cuneiform'
        boneout = 8;
    case 'lateral cuneiform'
        boneout = 9;
    case 'mt1'
        boneout = 10;
    case 'mt2'
        boneout = 11;
    case 'mt3'
        boneout = 12;
    case 'mt4'
        boneout = 13;
    case 'mt5'
        boneout = 14;
    case 'ph1'
        boneout = 15;
    case 'ph2'
        boneout = 16;
    case 'ph3'
        boneout = 17;
    case 'ph4'
        boneout = 18;
    case 'ph5'
        boneout = 19;
    case 'ses_hull'
        boneout = 21;
    case 'tib'
        boneout = 1;
    case 'fib'
        boneout = 2;
    case 'tal'
        boneout = 3;
    case 'cal'
        boneout = 4;
    case 'nav'
        boneout = 5;
    case 'cub'
        boneout = 6;
    case 'cmm'
        boneout = 7;
    case 'cmi'
        boneout = 8;
    case 'cml'
        boneout = 9;
    case 'mt1'
        boneout = 10;
    case 'mt2'
        boneout = 11;
    case 'mt3'
        boneout = 12;
    case 'mt4'
        boneout = 13;
    case 'mt5'
        boneout = 14;
    case 'ph1'
        boneout = 15;
    case 'ph2'
        boneout = 16;
    case 'ph3'
        boneout = 17;
    case 'ph4'
        boneout = 18;
    case 'ph5'
        boneout = 19;
    case 'ses'
        boneout = 20;
    case 1
        boneout = 'tib';
    case 2
        boneout = 'fib';
    case 3
        boneout = 'tal';
    case 4
        boneout = 'cal';
    case 5
        boneout = 'nav';
    case 6
        boneout = 'cub';
    case 7
        boneout = 'cmm';
    case 8
        boneout = 'cmi';
    case 9
        boneout = 'cml';
    case 10
        boneout = 'mt1';
    case 11
        boneout = 'mt2';
    case 12
        boneout = 'mt3';
    case 13
        boneout = 'mt4';
    case 14
        boneout = 'mt5';
    case 15
        boneout = 'ph1';
    case 16
        boneout = 'ph2';
    case 17
        boneout = 'ph3';
    case 18
        boneout = 'ph4';
    case 19
        boneout = 'ph5';
    case 20
        boneout = 'ses';
    case 21
        boneout = 'ses_hull';
    otherwise
        boneout = 0;
%         disp('Invalid Entry')
%         return
end %switch