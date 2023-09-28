function [lowerThresh, upperThresh] = findThresholds(confValues, ...
    ~, ParamStruct, currentBlockType)
% Find the relevant confidence bin thresholds

relevantThresholds = ParamStruct.Thresholds(:, currentBlockType);


% Sort and add extreme thresholds
relevantThresholds = [-inf; sort(relevantThresholds); inf];


% Check in order
if any(diff(relevantThresholds) < 0); error('Bug'); end


lowerThresh = relevantThresholds(confValues);
upperThresh = relevantThresholds(confValues+1);


end