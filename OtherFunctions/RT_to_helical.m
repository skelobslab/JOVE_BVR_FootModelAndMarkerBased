function [phi,n,t_ham,q] = RT_to_helical(R,T);
% %  This procedure calculates the helical axis of the mapping
% %  R (3x3) and T (1x3). Returns the angle in phi degrees, unit Ham in n (1x3), 
% %  translation along HAM,and a point Q (1x3).
% 
% % Modified 9/02 SS
% % Different formulas were used for situation where 1 or 2 components of n are zero. 
% % as described in page 454 of Panjabi's paper (using R11 and R12 instead of R13 and R33)
% % the situation for n = [0 0 0] returns NaN as of now, can add in a specific situation for 
% % that.
flag = 0; %Used later to look for zero rotation
c = (R(1,1) - 1)*(R(2,2) - 1) - R(1,2)*R(2,1);  %C value defined using rows 1 and 2 of R
if c~=0,
    if abs(c)<2.5e-17,  % Cutoff for z=0 where c approaches zero
        c=(R(2,1))*(R(3,2))-(R(2,2)-1)*R(3,1);%c value defined using rowns 2 and 3 of R
        a=((R(2,2)-1)*(R(3,3)-1)-(R(3,2))*R(2,3))/c;
        b=(R(2,3)*R(3,1)-R(2,1)*(R(3,3)-1))/c;
    else,  % z not zero
        a = (R(1,2)*R(2,3) - R(1,3)*(R(2,2) -1))/c;
        b = (R(1,3)*R(2,1) - R(2,3)*(R(1,1) - 1))/c;
    end;
    
    n(3) = sqrt(1/(1 + a^2 + b^2));
    n(1) = a*n(3);
    n(2)= b*n(3);
    
    if abs(n(2))<10e-15, % If y=0, n2 approaches zero, so use different equations without n2..
        %        in denominator
        cos_phi = (R(1,1)-n(1)^2)/(1-n(1)^2); %R11 = M11
        sin_phi = -R(1,2)/n(3); %R12 = M12
    else,
        cos_phi = (R(3,3) - n(3)^2)/(1 - n(3)^2); %R33 = M33
        sin_phi = (R(1,3) - n(1)*n(3)*(1 - cos_phi))/n(2); %R13 = M13
    end; 
    
    
    %-----------------------
else,
    myIndex = find(R==1);
    for cntr = 1:length(myIndex),
        n=zeros(3,1);
        %% myOrder: first is index of n that = 1 (rotation axis), 
        %%          second is component of R matrix that is cos phi
        %%          third is component of R matrix that is sin phi
        if myIndex(cntr) == 1,
            myOrder = [1,5,6]; 
        end;   
        if myIndex(cntr) == 5,
            myOrder = [2,1,7];   
        end;
        if myIndex(cntr) ==9,
            myOrder = [3,1,2];  
        end; 
    end;
    
    if R==eye(3),  % 0 rotation is identity matrix
        flag = 1;
    end;
    
    n(myOrder(1))= 1; % Set n based on location of 1 in rotation matrix
    cos_phi = R(myOrder(2));
    sin_phi = R(myOrder(3));
    n=n';
end; 
%--------------------
phi = atan2(sin_phi,cos_phi)*180/pi;
t_ham = dot(T,n);
%From Panjabi et al., 1981
%let vector a = [0,0,0], then rA = T;
e = T - n.*t_ham;
if flag == 1, %ZERO ROTATION
    q = [0 0 0];
    phi = 0;
    n = [0 0 0];
    t_ham = 0;
else,
    q = e./2 + cross(n,e)./(2*tan(phi*pi/180/2));
end;
%Direction Trapping - fix all Phi's to positive
%this is needed for error calculations,  Mathematically
%equivalent values w/opposite orientations cause
%problems... (+5 deg, +5 mm, + x is equal to -5 deg, -5 mm, -x)
%R. McGovern 9/22
if phi < 0,
    phi = -phi;
    n = -n;
    t_ham = -t_ham;
end;


