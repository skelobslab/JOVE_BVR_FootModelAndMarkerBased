function outData = convertRotation(inData,intype,outtype)

% Takes an input type of rotation translation and converts it to the
% specified type of outtype rotation translation.
%
% -------------------INPUT VARIABLES ------------------------------------
% inData  =   the raw rotations, autoscoper raw, can be an Anim (wrist
%               viz format), 4x4matrix, quaternion, helical axis
%
% intype    =   string describing the type of the input data
%               'autoscoper' -> raw output from autoscoper imported with
%                              csvread- with export format cols
%               'autoscoperRows' -> raw output from autoscoper imported with
%                              csvread,with export format rows
%               'anim' -> has the rotation matrix [3x3], then the
%                         translation [1x3] for each frame (rows)
%               '4x4 stacked'  -> 4x4 pose matrix - [[R- 3x3] [T- 3x1]
%                                                     0  0 0    1    ]
%                                  with every four rows starting a new
%                                  frame
%               '4x4xn'       -> same as 4x4 stacked, but the third
%                               dimension is the frame i.e. inputRot(:,:,5)
%                               gives the 4x4 T matrix for the fifth frame
%               'quaternion' -> [s, v1, v2, v3,tx, ty, tz] for each row a 
%                               diff. frame, s is scalar, v is quaternion
%                               vector, t is the translation
%                                   
%               'helical' -> [phi,n,L,s] with each row a different frame

% outtype   =  string describing the type of the output data - same as
%               input data types
%               'autoscoper' -> raw output from autoscoper imported with
%                              csvread,with export format cols
%               'autoscoperRows' -> raw output from autoscoper imported with
%                              csvread,with export format rows
%               'anim' ->   has the rotation matrix [3x3], then the
%                           translation [1x3] for each frame (rows)
%               '4x4 stacked'  -> 4x4 pose matrix - [[R- 3x3] [T- 3x1]
%                                                     0  0 0    1    ]
%                                  with every four rows starting a new
%                                  frame
%               '4x4xn'       -> same as 4x4 stacked, but the third
%                               dimension is the frame i.e. inputRot(:,:,5)
%                               gives the 4x4 T matrix for the fifth frame
%               'quaternion' -> [s, v1, v2, v3,tx, ty, tz] for each row a 
%                               diff. frame, s is scalar, v is quaternion
%                               vector, t is the translation
%               'helical' -> [phi,n,L,s] with each row a different frame
% ------------------OUTPUT VARIABLES ------------------------------------
% outData  = rotation and translations described as specified by outtype
% ----------------------------------------------------------------------
% Written by L. Welte Oct 2018


% convert all types to 4x4xn


switch intype
    case 'autoscoper'
        
        nfr = size(inData,1);
        T = repmat(eye(4,4),1,1,nfr);
        for i = 1:nfr
            T(1:4,1:4,i) = reshape(inData(i,1:16),4,4);
        end
    case 'autoscoperRows'
        
        nfr = size(inData,1);
        T = repmat(eye(4,4),1,1,nfr);
        for i = 1:nfr
            T(1:4,1:4,i) = reshape(inData(i,1:16)',4,4);
%             T(4,4,i) = 1;
        end
        
    case 'anim'
        nfr = size(inData,1)/4;
        T = repmat(eye(4,4),1,1,nfr);
        ct = 1;
        for i = 1:4:size(inData,1)
            T(1:3,1:3,ct) = inData(i:i+2,1:3);
            T(1:3,4,ct) = inData(i+3,1:3);
            T(4,4,ct) = 1;
            ct = ct + 1;
        end
        
    case '4x4 stacked'
        nfr = size(inData,1)/4;
        T = repmat(eye(4,4),1,1,nfr);
        ct = 1;
        for i = 1:4:size(inData,1)
            T(1:4,1:4,ct) = inData(i:i+3,1:4);
            ct = ct + 1;
        end
    case '4x4xn'
        nfr = size(inData,3);
        T = inData;
    case 'quaternion'

        nfr = size(inData,1);
        T = repmat(eye(4,4),1,1,nfr);
        for i = 1:nfr
            if any(isnan(inData(i,:)))
                T(:,:,i) = nan(4,4);
            else
                R = quat2rotm(inData(i,1:4));
                T(1:3,1:3,i) = R;
                T(1:3,4,i) = inData(i,5:7);
            end
        end
    case 'helical'
        error('Helical axis is not a currently supported intype.')
        
    otherwise
        error('The specified input rotation type is not defined. Please check spelling or accepted rotation formats')
end

switch outtype
    case 'autoscoper'
        
        
        for i = 1:nfr
            outData(i,1:16) =  reshape(T(1:4,1:4,i),1,16);
        end
        
    case 'autoscoperRows'
        
        for i = 1:nfr
            Ttemp = T(1:4,1:4,i);
            outData(i,1:16) =  reshape(Ttemp',1,16);
        end
        
    case 'anim'
        ct = 1;
        for i = 1:4:nfr*4
            outData(i:i+2,1:3) = T(1:3,1:3,ct);
            outData(i+3,1:3) = T(1:3,4,ct);
            ct = ct + 1;
        end
        
    case '4x4 stacked'
        ct = 1;
        for i = 1:4:nfr*4
            outData(i:i+3,1:4) = T(1:4,1:4,ct);
            ct = ct + 1;
        end
    case '4x4xn'
        outData = T;
    case 'quaternion'
        for i = 1:nfr
            if any(isnan(T(:,:,i)))
                outData(i,:) = nan(1,7);
            else
                outData(i,1:4) = rotm2quat(T(1:3,1:3,i));
                outData(i,1:4) = unit(outData(i,1:4));
                outData(i,5:7) = T(1:3,4,i);
            end
        end
    case 'helical'
        for i = 1:nfr
            [phi,n,L,s] = helical(T(1:4,1:4,i));
            outData(i,1:8) = [phi,n',L,s'];
        end
    otherwise
        error('The specified output rotation type is not defined. Please check spelling or accepted rotation formats')
end





end





function varargout = helical(T)

% Compute the helical axis parameters using Veldpaus and Spoor (1980)
% Use a pose matrix defined between two segments (e.g. tibia to femur).
% ---------Input variables -----------------
% T = 4x4 pose matrix - [[R- 3x3] [T- 3x1]
%                         0  0 0    1    ]
% ---------Output variables-----------------
% [phi,n,L,s] -> variable, so put phi = helical(T) if only the first
% is wanted, or [phi,n] = helical(T)... if first two are wanted etc
%
% phi   = the rotation about the helical axis
% n     = the unit vector in the direction of the helical axis
% L     = the translation along the helical axis
% s     = a point on the helical axis, referenced to the origin of the
%            reference segment (in that co-ordinate system
% Written by L. Welte, June 23/2017

R = T(1:3,1:3);
t = T(1:3,4);

temp = [R(3,2)-R(2,3),R(1,3)-R(3,1),R(2,1)-R(1,2)];

rot_val = 1/2 * sqrt((R(3,2)-R(2,3))^2 + (R(1,3) - R(3,1))^2 + (R(2,1)- R(1,2))^2);

phi = asind(rot_val);

if rot_val  > sqrt(2)/2
    rot_val = 1/2 * (R(1,1) + R(2,2) + R(3,3) -1);
    phi = acosd(rot_val);
end

n(1:3,1) = temp/(2*sind(phi));

L = n(1:3)'*t(1:3); % translation along the normal

s = -0.5 * cross(n(1:3),cross(n(1:3),t(1:3))) + sind(phi)/(2*(1-cosd(phi))) * cross(n(1:3),t(1:3)); % radius vector of point on the axis

varargout = {phi,n,L,s};
end










