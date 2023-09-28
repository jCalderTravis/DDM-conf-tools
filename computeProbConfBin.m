function probConf = computeProbConfBin(ParamStruct, Data, incTrials, ...
    currentBlockType, xMean, xStd, truncateDist)
% Find the probability of the x_ll falling into the confidence bin in which it
% was indeed found. For use in cm_computeTrialLL.m.

% INPUT
% truncateDist: Truncate the integration, so don't integrate anything below zero

% Find the relevant confidence bin thresholds
[lowerThresh, upperThresh] = findThresholds(Data.ConfCat(incTrials), ...
    [], ParamStruct, currentBlockType);


% Defesnive programming
if any(lowerThresh > upperThresh); error('Bug'); end


if truncateDist
    upperThresh(upperThresh < 0) = 0;
    lowerThresh(lowerThresh < 0) = 0;
end


% On trials in which the response was R=1, flip the thresholds around zero
toFlip = Data.Resp == 1;
multiplier = ones(size(Data.Resp));
multiplier(toFlip) = -1;
multiplier = multiplier(incTrials);

lowerThresh = multiplier .* lowerThresh;
upperThresh = multiplier .* upperThresh;


% Use the multiplier here as well as in trials in which the response was R=1 we
% need to swtich the limits around.
probConf = multiplier .* (normcdf(upperThresh, xMean, xStd) ...
    - normcdf(lowerThresh, xMean, xStd));


% Defensive programming: These calculations assume that confidence categories
% are all 1 or greater
if any(Data.ConfCat < 1); error('Bug'); end
if any(probConf < 0); error('Bug'); end
if any(probConf > 1); error('Bug'); end

end


