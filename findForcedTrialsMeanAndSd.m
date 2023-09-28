function [confMean, standardDev] = findForcedTrialsMeanAndSd(Data, ...
    forcedTrials, forcedCode, ParamStruct, DSetSpec, gamma)
% Computes the mean and SD from the derivations for the forced condition 
% when no metacognitive noise is present

% We need to calcuate the value used to transform from x_r (raw) to
% x_ll(monotonic in log-likelihood).
timeDiscount = 1 - gamma(forcedCode) + ...
    (gamma(forcedCode) * Data.ActualDurationPrec(forcedTrials));


% We need to compute the proberties of the normal distirbution describing x_ll
confMean = Data.TotalPreRespEv(forcedTrials)./timeDiscount;

numeratorTermA = ((Data.TotalPreRespEv(forcedTrials)).^2) ...
    *(ParamStruct.Sigma_phi(forcedCode)^2);
numeratorTermB = Data.ActualDurationPrec(forcedTrials) * ...
    (ParamStruct.Sigma_acc(forcedCode)^2);

standardDev = ((numeratorTermA + numeratorTermB).^(0.5)) ./ timeDiscount;