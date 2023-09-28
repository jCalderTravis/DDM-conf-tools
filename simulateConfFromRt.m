function [SimConf, estEvQual] = simulateConfFromRt(model, ...
    findIncludedTrials, ParamStruct, Data, DSetSpec)
% Using the chosen model, simulate confidence given response time, and response

% Check input
if length(Data) ~= 1
    error('Input Data should be for one participant only')
end

if (length(model) < 21) ...
        || strcmp(model(21:24), 'NoRg')
    % Everything is good
    
elseif any(strcmp(model(21:24), {'Reg1', 'Reg2'}))
    model(21:24) = 'NoRg';
    warning('Turning off regularisation for the simulation of confidnece.')
else
    error('Unknown model specification.')
end

% How many confidence bins are there?
confBins = size(ParamStruct.Thresholds, 1) +1;

% For each bin, find the probability of a confidence report in that bin
probBin = NaN(length(Data.ConfCat), confBins);

for iBin = 1 : confBins
    HypotheticalData = Data;
    HypotheticalData.ConfCat = repmat(iBin, [length(Data.ConfCat), 1]);
    
    [trialLL, estEvQual] = cm_computeTrialLL(model, ...
        findIncludedTrials, ParamStruct, HypotheticalData, DSetSpec, ...
        'nearestVal');
    
    probBin(:, iBin) = exp(trialLL);
end

% Now draw confidence reports according to their probability
cumulativeProb = cumsum(probBin, 2);

validTrials = findIncludedTrials(Data);

tol = 0.00005;
if ~all((cumulativeProb(validTrials, end) > (1-tol)) & ...
        (cumulativeProb(validTrials, end) < (1+tol)))
    
    problems = ~((cumulativeProb(validTrials, end) > (1-tol)) & ...
        (cumulativeProb(validTrials, end) < (1+tol)));
    
    problemValidTrials = validTrials;
    problemValidTrials(validTrials) = problems;
    disp('*******************************')
    problemValidWithinFree = problemValidTrials(~Data.IsForcedResp);
    problemValidWithinForced = problemValidTrials(...
        logical(Data.IsForcedResp));
    
    disp('Indicies within free trials of problem trials:')
    disp(find(problemValidWithinFree))
    
    disp('Indicies within forced trials of problem trials:')
    disp(find(problemValidWithinForced))
    
    disp('Lapse rate')
    disp(ParamStruct.LapseRate)
    
    disp('Cumulative probabilities')
    table(cumulativeProb(problemValidTrials, end))
    disp('*******************************')
    error('Bug')
end

cumulativeProb = [zeros(length(Data.ConfCat), 1), cumulativeProb(:, 1:(end-1))];

drawnBin = rand(length(Data.ConfCat), 1) > cumulativeProb;
SimConf = sum(drawnBin, 2);