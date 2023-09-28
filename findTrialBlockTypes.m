function [freeTrials, forcedTrials, blockTypes, numBlockTypes, includedTrials] ...
    = findTrialBlockTypes(Data, findIncludedTrials, DSetSpec)
% Does various things, helpful to working out which trials belong to which
% blocks

if isstring(findIncludedTrials) || ischar(findIncludedTrials)
    findIncludedTrials = str2func(findIncludedTrials); 
end

% Find some info about the input
blockTypes = unique(Data.BlockType);
numBlockTypes = sum(~isnan(blockTypes));

% Find the trials from each block type which are valid trials
includedTrials = findIncludedTrials(Data);
freeTrials = (~Data.IsForcedResp) & includedTrials;
forcedTrials = Data.IsForcedResp & includedTrials;
postRespEvTrials = includedTrials & ...
    (round(Data.ActualDurationPrec * DSetSpec.Fps) > ...
        ceil(Data.RtPrec * DSetSpec.Fps));

if any(forcedTrials & postRespEvTrials)
    error('Script cannot deal with this case.')
end