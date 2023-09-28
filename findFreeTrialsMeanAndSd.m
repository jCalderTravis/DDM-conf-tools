function [confMean, standardDev, estEvQual] = findFreeTrialsMeanAndSd(Data, ...
    freeTrials, freeCode, gamma, ParamStruct, DSetSpec)

% We need to calcuate the value used to transform from x_r (raw) to
% x_ll(monotonic in log-likelihood).
timeDiscount = 1 - gamma(freeCode) + ...
    (gamma(freeCode) * Data.ActualDurationPrec(freeTrials));

adjustedPipe = computeAdjuedtedPipeTime(DSetSpec, Data, ...
    freeTrials, ParamStruct);

% We need to compute the properties of the Normal distirbution describing x_ll.
% First compute some components.

% DV (in accumualtor space) at time of decision
x_D = findDvAtDecision(ParamStruct, Data, freeTrials, adjustedPipe, ...
    'respCoding');

% We will interpolate between the nearest two precomputed values for the
% duration of the pipeline when computing evidence totals
upperIdx = ceil(adjustedPipe*DSetSpec.Fps) +1;
lowerIdx = floor(adjustedPipe*DSetSpec.Fps) +1;
truePos = (((adjustedPipe*DSetSpec.Fps) +1) - lowerIdx) ./ (upperIdx - lowerIdx);

% Convert to linear indicies
relPipeEv = Data.AllLagPipeEv(freeTrials, :);
upperLinIdx = sub2ind(size(relPipeEv), [1:size(relPipeEv, 1)]', upperIdx);
lowerLinIdx = sub2ind(size(relPipeEv), [1:size(relPipeEv, 1)]', lowerIdx);

upperVal = relPipeEv(upperLinIdx);
lowerVal = relPipeEv(lowerLinIdx);

% Do we actually need to interpolate?
noInterp = upperIdx == lowerIdx;
interp = ~noInterp;

pipelineE = NaN(size(upperVal));

pipelineE(noInterp) = lowerVal(noInterp);

interpolatedVal = (upperVal(interp).*truePos(interp)) ...
    + (lowerVal(interp) .* (1 - truePos(interp)));
pipelineE(interp) = interpolatedVal;


% What is the total evidence gathered after a decision?
postDecisEv = pipelineE + Data.TotalPostRespEv(freeTrials);
assert(all(Data.TotalPostRespEv(freeTrials) == 0))

% Evidence presented between onset of stimulus and decision. Interpolate again.
relPreDecis = Data.AllLagMeanPreDecEv(freeTrials, :);

upperVal = relPreDecis(upperLinIdx);
lowerVal = relPreDecis(lowerLinIdx);

if ~(size(relPipeEv) == size(relPreDecis))
    error('Code assumes this as uses same linear indecies for interpolation.')
end

% Do we actually need to interpolate?
noInterp = upperIdx == lowerIdx;
interp = ~noInterp;

meanPreDecisionE = NaN(size(upperVal));

meanPreDecisionE(noInterp) = lowerVal(noInterp);
    
interpolatedVal = (upperVal(interp).*truePos(interp)) ...
    + (lowerVal(interp) .* (1 - truePos(interp)));
meanPreDecisionE(interp) = interpolatedVal;
    

% For both the mean and the varience we have the same denominator in a fraction
preComputedDenom = ...
    ((Data.RtPrec(freeTrials) - ParamStruct.PipelineI) ...
    .* (meanPreDecisionE.^2) ...
    * (ParamStruct.Sigma_phi(freeCode)^2)) ...
    + (ParamStruct.Sigma_acc(freeCode)^2);


% We are now in a position to compute the mean and standard deviaion.
% First compute mean in raw accumulator space. Then convert.
fracNumerator = (x_D .* (ParamStruct.Sigma_phi(freeCode)^2) .* meanPreDecisionE) + ...
    (ParamStruct.Sigma_acc(freeCode)^2);

unadjustedMean = x_D + (postDecisEv .* (fracNumerator ./ preComputedDenom));

confMean = unadjustedMean ./ timeDiscount;


% Standard deviation
fracNumerator = (postDecisEv.^2) * (ParamStruct.Sigma_phi(freeCode)^2);
varience = (((ParamStruct.Sigma_acc(freeCode) ./ timeDiscount)).^2).* ...
    ( (fracNumerator ./ preComputedDenom) + adjustedPipe);


% So far we have computed \sigma_lf^2 from the derivations. We now need to add
% metacognitive noise
standardDev = (varience + (ParamStruct.MetacogNoise(freeCode).^2)).^(1/2);

% Below functionality was removed. Returns nans for compatability
estEvQual = nan(size(preComputedDenom));


