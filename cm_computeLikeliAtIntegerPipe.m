function [trialLL, estEvQual] = cm_computeLikeliAtIntegerPipe(model, ...
    findIncludedTrials, ParamStruct, Data, DSetSpec)
% Computes the log-liklihood of the parameters for each trial, but only at
% values of the PipelineI parameter which are multiples of (1/frames per sec).

% INPUT
% model         16, 20 or 24 letter string. 
%               First 4 letters: (NDsc) no time discounting, (TrDs) true
%               time discounting or (FaDs) false time discounting
%               Second 4 letters: (Flat) flat threshold or (Slpe) sloped
%               Third 4 letters: (Dvar) drift rate variability or (None) not
%               Fourth 4 letters: (Same) all block types use same parameters, or
%               (Diff) each block type uses different free parameters
%               Fifth 4 letters (optional): (Mvar) metacognitive noise, or 
%               (NoMV) none 
%               Sixth 4 letters (optional): (Reg1) or (Reg2) use a 
%               regularisation strategy which aims to fit to some of the 
%               response and RT data, or (NoRg) no regularlisation 
%               (default).
% findIncludedTrials: String which will be turned into function, or a function. 
%               Accepts DSet.P(i).Data, and returns logical
%               vector of included trials.
% ParamStruct:  struct. Fields...
%   Sigma_phi
%   Sigma_acc
%   Thresholds  [(num conf thresholds) x (num block types)] array if using 
%               different parameters for different block types, otherwise
%               [num conf categories x  1] array. Excludes explicit
%               specificiation of threshiolds at inf and -inf. 
%   BoundIntercept  Decribes the position of the observers deliberation
%                   termination bound
%   BoundSlope
%   PipelineI   Duration of the pipeline (seconds)
%   MetacogNoise
% Data  Struct with fields...
%   ConfCat
%   ConfCatProp
%               [numBlockTypes] long cell array. Each field contains the 
%               data for one blocktype in a [num categories x response] 
%               array. Summing along the first dimention, leads to a row 
%               of ones.
%   AllLagMeanPreDecEv             
%   AllLagPipeEv
%               These two matricies represent the average evidence 
%               per frame pre-decision, and the total evidence in the pipeline. 
%               Both matricies are [num trials x hypothesised pipeline 
%               lengths] in size. If the hypothesised
%               pipeline length is I = 0.2s, then the relevant column of 
%               the output matricies is: round(I/0.05)+1
%   TotalPreRespEv Vector representing the total evidence presented each trial
%               before the response.

% NOTES
% -- Positive evidence is assumed to be evidence for response 2
% -- The time discount calculation will be incorrect if there is 
% post-decisional evidence

% HISTORY
% 28.09.2023 Checked maths in code matches maths in the derivations paper
%   and in the symbol definitions table.


%% Setup

% Check input
if length(Data) ~= 1
    error('Input Data should be for one participant only')
end

[freeTrials, forcedTrials, blockTypes, numBlockTypes, includedTrials] ...
    = findTrialBlockTypes(Data, findIncludedTrials, DSetSpec);

% All models' predictions can be computed with the same code, by simply not
% allowing some parameters to be free, but rather stipulating them.
[ParamStruct, gamma, reguMode] = setupParams(model, ParamStruct, ...
    numBlockTypes, DSetSpec);

freeParamPos = 1;
forcedParamPos = 2;

% Initialise
finalProbConf = NaN(length(Data.BlockType), 1);
finalProbConfGivenLapse = NaN(length(Data.BlockType), 1);
finalProbLapse = NaN(length(Data.BlockType), 1);
finalRegCost = NaN(length(Data.BlockType), 1);


%% Forced block case
if sum(forcedTrials) > 0
    
    % What is the probability the trials were the result of a lapse?
    pLapse = repmat(ParamStruct.LapseRate(forcedParamPos), ...
        length(Data.BlockType(forcedTrials)), 1);
    
    % What about the result of the standard process?
    [confMean, standardDev] = findForcedTrialsMeanAndSd(Data, ...
        forcedTrials, forcedParamPos, ParamStruct, DSetSpec, gamma);

    % How we treat the remainder of the computation will depend on whether we are
    % applying metacognitive noise or not. Things are much simpler without it.
    % If accumulator noise is much greater than metacognitive noise, we will
    % just ignore the metacognitive noise.
    if ParamStruct.MetacogNoise(forcedParamPos) == 0
        useMetNoise = false(sum(forcedTrials), 1);
        
    else
        useMetNoise = true(sum(forcedTrials), 1);
        useMetNoise( ...
            (standardDev / ParamStruct.MetacogNoise(forcedParamPos)) > (10^5)) ...
            = false;
        
    end
    
    % What is the probability of the responses?
    probResp = normcdf(0, confMean, standardDev);
    probResp(Data.Resp(forcedTrials) == 2) ...
        = 1 - probResp(Data.Resp(forcedTrials) == 2);
    assert(~any(isnan(Data.Resp(forcedTrials))))
    
    % Analyse without metacognitive noise
    if any(~useMetNoise)
        
        % What is the probability of the confidence report?
        probConfNoMvar = computeProbConfBin(ParamStruct, Data, ...
            forcedTrials, forcedParamPos, confMean, ...
            standardDev, true);
        
        % We need to divide this by the probability of the response
        probConfNoMvar = probConfNoMvar./probResp;
    end
    
    % Analyse with metacognitive noise
    if any(useMetNoise)
        
        relevantForcedTrials = forcedTrials;
        relevantForcedTrials(forcedTrials) = useMetNoise;
        
        theseConfVals = evaluateForcedIntegral('new', Data, ParamStruct, ...
            forcedParamPos, relevantForcedTrials, ...
            standardDev(useMetNoise), ...
            confMean(useMetNoise));
        
        probConfWithMvar = NaN(sum(forcedTrials), 1);
        probConfWithMvar(useMetNoise) = theseConfVals;
    end
    
    % Use the result with metacognitive noise when we want this, and the result
    % without when we want this
    if all(useMetNoise)
        probConf = probConfWithMvar;
        
    elseif all(~useMetNoise)
        probConf = probConfNoMvar;
        
    else
        probConf = NaN(length(probConfWithMvar), 1);
        probConf(useMetNoise) = probConfWithMvar(useMetNoise);
        probConf(~useMetNoise) = probConfNoMvar(~useMetNoise);
    end
    
    % If the probability of the response very small then treat the trial 
    % as not generated by the standard process
    smallProbResp = probResp < (10^(-15));
    probConf(smallProbResp) = 0;
    pLapse(smallProbResp) = 1;
    
    % What is the probability of the confidence report given a lapse?
    probGivenLapse = computeProbGivenLapse(Data.ConfCatProp{forcedParamPos}, ...
        Data.ConfCat(forcedTrials)); 

    % Numerical integration can lead to probability estimates which are 
    % slightly greater than 1 or less than 0. Set these to 1 or 0.
    tolerance = 0.0001;
    slightlyAbove = (probConf > 1) & (probConf < (1 + tolerance));
    probConf(slightlyAbove) = 1;
    
    slightlyBelow = (probConf < 0) & (probConf > -tolerance);
    probConf(slightlyBelow) = 0;
    
    % Store data for relevant trials
    finalProbConf(forcedTrials) = probConf;
    finalProbConfGivenLapse(forcedTrials) = probGivenLapse;
    finalProbLapse(forcedTrials) = pLapse;
    
    if any((~isnan(Data.Conf(forcedTrials))) & ...
            (~(probConf>=0 & probConf <= 1)))
        error('Bug')
    end
end

if any(strcmp(reguMode, {'Reg1', 'Reg2'})) && (sum(forcedTrials) > 0)
    finalRegCost(forcedTrials) = findForcedCondRegularisationCost(Data, ...
        forcedTrials, ParamStruct, probResp);
else
    assert(strcmp(reguMode, 'NoRg'))
end


%% Free block case

if sum(freeTrials) > 0
    estEvQual = NaN(size(freeTrials));
    
    % Is the response at least one frame after the end of the pipeline? If not
    % treat as invalid trial.
    invalidFreeReport = Data.RtPrec(freeTrials) ...
        <= ParamStruct.PipelineI;
    
    % Are there any valid trials?
    if sum(~invalidFreeReport) > 0
        
        [confMean, standardDev, estEvQualFree] = findFreeTrialsMeanAndSd(Data, ...
            freeTrials, freeParamPos, gamma, ParamStruct, DSetSpec);
        
        estEvQual(freeTrials) = estEvQualFree;
        
        % What is the probability of the confidence category given?
        probConf = computeProbConfBin(ParamStruct, Data, freeTrials, ...
            freeParamPos, confMean, ...
            standardDev, false);
    else
        probConf = nan(sum(freeTrials), 1);
    end
    
    % Lapses
    pLapse = repmat(ParamStruct.LapseRate(freeParamPos), ...
        length(Data.BlockType(freeTrials)), 1);
    
    % But all invalid reports are certainly lapses
    probConf(invalidFreeReport) = 0;
    pLapse(invalidFreeReport) = 1;
    
    % What is the probability of the confidence report given a lapse?
    probGivenLapse = computeProbGivenLapse(Data.ConfCatProp{freeParamPos}, ...
        Data.ConfCat(freeTrials));
    
    % Store data for relevant trials
    finalProbConf(freeTrials) = probConf;
    finalProbConfGivenLapse(freeTrials) = probGivenLapse;
    finalProbLapse(freeTrials) = pLapse;
    
    if any( ~isnan(Data.Conf(freeTrials)) & ~(probConf>=0 & probConf <= 1))
        problem = find( ~isnan(Data.Conf(freeTrials)) ...
            & ~(probConf>=0 & probConf <= 1));
        probConf(problem)
        ParamStruct
        ParamStruct.Thresholds
        error('Bug')
    end
end

if any(strcmp(reguMode, {'Reg1', 'Reg2'}))
    finalRegCost(freeTrials) = findFreeCondRegularisationCost(DSetSpec, Data, ...
        freeTrials, ParamStruct, invalidFreeReport, freeParamPos);
else
    assert(strcmp(reguMode, 'NoRg'))
end

%% All trials

% Combining the possibility of a lapse, and no lapse
trialL = ((1 - finalProbLapse) .* finalProbConf) ...
    + (finalProbLapse .* finalProbConfGivenLapse);

if any(includedTrials & ~(trialL>=0 & trialL <=1))  
    error('Bug')
end

if any( ~includedTrials & ~(isnan(trialL)))  
    error('Bug')
end

trialLL = log(trialL);

if any(strcmp(reguMode, {'Reg1', 'Reg2'}))
    assert(~any(isnan(finalRegCost(includedTrials))))
    assert(isequal(size(finalRegCost), size(trialLL)))

    if strcmp(reguMode, 'Reg1')
        multiplier = 1;
    elseif strcmp(reguMode, 'Reg2')
        multiplier = 10;
    else
        error('Bug')
    end
    
    trialLL = trialLL - (multiplier * finalRegCost);
else
    assert(strcmp(reguMode, 'NoRg'))
end


end

function probGivenLapse = computeProbGivenLapse(confCatProp, confCats) 

% INPUT
% ConfCatProp: a [num categories x response] array giving the proportion of trials. 
% falling into each category. Summing along the first
% dimention, leads to a row of ones.

numBins = size(confCatProp, 1);

probGivenLapse = ones(size(confCats));
probGivenLapse = probGivenLapse * (1/numBins);

end