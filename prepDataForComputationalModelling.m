function [DSet, binEdges] = prepDataForComputationalModelling(DSet, binning, ...
    varargin)
% The likelihood function computation assumes we have precomputed certain
% values and stored them in 'DSet.P(i).Data'.

% INPUT
% binning           'sep', or 'together' affects whether we bin all 
%                   confidence data together or seperately for different 
%                   blocks.
% varargin{1}       (default is false) Should we artificially break 
%                   ties in the confidence scale? 
% varargin{2}       (default is true) Compute average drift rate? Does not work
%                   if have different underlying drift rates on different
%                   trials.

% OUTPUT
% binEdges  For the final participant only, gives the edges of the 
%           confidence bins in values of the original
%           confidence scale. See mT_makeOrdinalVar for more information.

if isempty(varargin)
    breakTies = false;
else
    breakTies = varargin{1};
end

if length(varargin) < 2
    computeMeanDrift = true;
else
    computeMeanDrift = varargin{2};
end

%% Bin confidence

for iPtpnt = 1 : length(DSet.P)

    blockType = DSet.P(iPtpnt).Data.BlockType;
    conf = DSet.P(iPtpnt).Data.Conf;
    
    BinSettings.DataType = 'integer';
    BinSettings.BreakTies = breakTies;
    BinSettings.Flip = false;
    BinSettings.EnforceZeroPoint = false;
    BinSettings.NumBins = DSet.FitSpec.NumBins;
    
    if strcmp(binning, 'sep')
        BinSettings.SepBinning = true;
    elseif strcmp(binning, 'together')
        BinSettings.SepBinning = false;
    end
    
    [DSet.P(iPtpnt).Data.ConfCat, indecisionPoint, ~, binEdges] = ...
        mT_makeVarOrdinal(BinSettings, conf, blockType, []);
    
    % Store the indecision point and seperately for the two block types, and response, 
    % compute the proportion of trials in each category 
    DSet.P(iPtpnt).Data.IndecisionPoint = indecisionPoint;
    DSet.P(iPtpnt).Data.ConfCatProp ...
        = computeConfCatProps(DSet.P(iPtpnt).Data, BinSettings.NumBins);
end

% Store settings
DSet.FitSpec.ConfBinningSettings = BinSettings;


%% Precomute evidence
% Mean predecision evidnece, and total pipeline evidence at every
% hypothesised pipeline duration
for iPtpnt = 1 : length(DSet.P)

    [totalPreRespEv, allLagMeanPreDecEv, allLagPipeEv, totalPostRespEv, ...
        totalPreSquared] ...
        = preComputePreAndPipeEvidence(DSet.Spec, DSet.P(iPtpnt).Data);
    
    DSet.P(iPtpnt).Data.TotalPreRespEv = totalPreRespEv;
    DSet.P(iPtpnt).Data.TotalPostRespEv = totalPostRespEv;
    DSet.P(iPtpnt).Data.AllLagMeanPreDecEv = allLagMeanPreDecEv;
    DSet.P(iPtpnt).Data.AllLagPipeEv = allLagPipeEv;
    DSet.P(iPtpnt).Data.TotalPreSquared = totalPreSquared;
end


%% Compute mean evidnece
% Compute the mean drift rate (the average evidence per second in the correct
% direction).

if computeMeanDrift
    % First find the mean dots difference and check it is the same accross all
    % trials
    allDotsDiff = mT_stackData(DSet.P, @(Struct) Struct.Data.Diff);
    
    dotsDiff = unique(round(allDotsDiff));
    
    if ~all(size(dotsDiff) == [1, 1])
        error('Code presumes dots diff same in all trials')
    end
    
    % Dots diff gives mean evidence but we want mean evidence per second.
    DSet.Spec.AvEvidence = dotsDiff * DSet.Spec.Fps;
end


