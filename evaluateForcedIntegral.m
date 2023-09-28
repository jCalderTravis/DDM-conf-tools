function probConf = evaluateForcedIntegral(method, Data, ParamStruct, ...
    forcedCode, relForcedTrials, oldStandardDev, oldMean)
% Perform the integral required in the free
% condition when metacognitive noise is present. 

% INPUT
% method: Depreachated. Must be set to 'new'

% Check input
if any(sum(relForcedTrials) ~= [length(oldStandardDev), length(oldMean)])
    error('Only pass mean and standard dev for trials to be analysed.')
end

% Need to computle the variable L from the derivations. Call it 'multipier'
% here
toFlip = Data.Resp == 1;
multiplier = ones(size(Data.Resp));
multiplier(toFlip) = -1;
multiplier = multiplier(relForcedTrials);

% Precompute some values. Some computations are the same for both methods
oldVarience = oldStandardDev.^2;
newVarience = (ParamStruct.MetacogNoise(forcedCode)^2) + oldVarience;
newStd = newVarience .^ (1/2);

oldNormalisation = normcdf((multiplier .* oldMean)./oldStandardDev);

% Find the relevant confidence bin thresholds
[lowerThresh, upperThresh] = findThresholds(Data.ConfCat(relForcedTrials), ...
    [], ParamStruct, forcedCode);

if strcmp(method, 'old')
    error('Depreceated')

elseif strcmp(method, 'new')
        
    % Pre-compute some values
    prefactor = 1 ./ oldNormalisation;
    varianceProduct = oldStandardDev .* ParamStruct.MetacogNoise(forcedCode);
    g = (multiplier .* oldMean .* newStd) ...
        ./ varianceProduct;
    h = (multiplier .* oldStandardDev) ./ ParamStruct.MetacogNoise(forcedCode);
    
    denom = (1 + (h.^2)).^(1/2);
    lim = g ./ denom;
    corr = - h ./ denom;

    % Transform thresholds
    newUpper = ((multiplier.*upperThresh) - oldMean) ./ newStd;
    newLower = ((multiplier.*lowerThresh) - oldMean) ./ newStd;
    
    % The matlab function gets confused if we give it too large bounds
    % in the mnvcdf function but don't mark them as infinity. If a bound
    % is >20 standard deviations away from zero, mark it as infinity.
    newUpper(newUpper > 20) = inf;
    newLower(newLower > 20) = inf;
    
    newUpper(newUpper < -20) = -inf;
    newLower(newLower < -20) = -inf;
    
    
    cumulativeDiff = NaN(sum(relForcedTrials), 1);
    
    for iForcedT = 1 : sum(relForcedTrials)
        % Evaluate the cumulative normal at the upper and lower bound
        % simultanously.
        thisLim = lim(iForcedT);
        covMatrix = [1, corr(iForcedT); corr(iForcedT), 1];
        
        [~,p] = chol(covMatrix);
        
        if p ~= 0
            error('Bug')
        end
        
        % The matlab function gets confused if we give it too large bounds
        % in the mnvcdf function but don't mark them as infinity. If a bound
        % is >20 standard deviations away from zero, mark it as infinity.
        if thisLim > 20
            thisLim = inf;
        end
        if thisLim < -20
            thisLim = -inf;
        end
        
        cumulativeNormalEvals ...
            = mvncdf(...
            [thisLim, newUpper(iForcedT); ...
            thisLim, newLower(iForcedT)] ...
            , [], covMatrix);
        
        cumulativeDiff(iForcedT) ...
            = multiplier(iForcedT) * (cumulativeNormalEvals(1) ...
            - cumulativeNormalEvals(2));
    end
    
    probConf = prefactor .* cumulativeDiff;
else
    error('Bug') 
end
    

