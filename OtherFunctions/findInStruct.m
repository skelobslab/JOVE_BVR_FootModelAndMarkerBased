function matchInd = findInStruct(InStruct,field,match)

% function will look in the column of the InStruct (input structure) and
% determine the indices where an exact match occurs. Works for input
% strings and input nuumeric.

% Determine if it's a string or a number
if isstr(match) == 1
    opt = 1;
elseif isnumeric(match) == 1
    opt = 2;
else
    error('Input match is not of a supported type.');
end


n = length(InStruct);
% 
% field = fields(InStruct);
% if size(field,1) ~= 1
%     error('Input array has more than one field.')
% end

count = 1;
matchInd = [];

for i = 1:n
    
    switch opt
        case 1
           mFlag = ~isempty(strfind(InStruct(i).(field),match));
        case 2
            mFlag = isequal(InStruct(i).(field),match);
    end
    
           if mFlag == 1
               matchInd(count) = i;
               count = count + 1;
           end
           
end