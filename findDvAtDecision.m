function x_D = findDvAtDecision(ParamStruct, Data, freeTrials, ...
    pipeDuration, codingMode)
% Find the decision variable (in accumulator space) at the time a 
% decision boundary is first crossed

% INPUT
% pipeDuration: Vecotor as long as the number of free condition trials.
%   Gives duration of the pipeline.
% codingMode: str. If 'respCoding', then positive values indicate the
%   boundary for one response was crossed, and negative values indicate
%   the boundary for the other response was crossed. If 'accCoding',
%   positive values indicate the boundary corresponding to the correct
%   response was crossed, while negative values indicate the boundary
%   corresponding to the incorrect response was crossed.

% OUTPUT
% x_D: vector as long as the number of free trials

assert(isequal(size(pipeDuration), [sum(freeTrials), 1]))

if strcmp(codingMode, 'respCoding')
    toFlip = Data.Resp == 1;
    assert(~any(isnan(Data.Resp(freeTrials))))
    
elseif strcmp(codingMode, 'accCoding')
    toFlip = Data.Acc == 0;
    assert(~any(isnan(Data.Acc(freeTrials)))) 
else
    error('Unrecognised option.')
end

multiplier = ones(size(Data.Resp));
multiplier(toFlip) = -1;

unflipped_x_D = ParamStruct.BoundIntercept + ...
    ((-1) * ParamStruct.BoundSlope ...
    .* (Data.RtPrec(freeTrials) - pipeDuration));

unflipped_x_D(unflipped_x_D < 0) = 0; % Decision bounds cannot cross zero

x_D = multiplier(freeTrials) .* unflipped_x_D;