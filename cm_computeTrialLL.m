function [trialLL, estEvQual] = cm_computeTrialLL(model, ...
    findIncludedTrials, ParamStruct, Data, DSetSpec, varargin)

% We can compute the likelihood only at values of the Pipeline I parameter
% which are multiples of (1 / frames per sec). Take the value of the 
% paramter and linearly interpolate between the two nearest values which 
% can be evaluated (default), or use the closest value.

% INPUT
% varargin: str. 'linearInterp' (default), or 'nearestVal' (to use only the
%  closest value of I in the evaluation.

if (~isempty(varargin)) && (~isempty(varargin{1}))
    approach = varargin{1};
else
    approach = 'linearInterp';
end

% Find nearest values
pipelineI = ParamStruct.PipelineI;
assert(length(pipelineI) == 1)
pipelineFrames = pipelineI * DSetSpec.Fps;

if strcmp(approach, 'linearInterp')
    nearestPipelineI = nan(1, 2);
    nearestPipelineI(1) = floor(pipelineFrames) / DSetSpec.Fps;
    nearestPipelineI(2) = ceil(pipelineFrames) / DSetSpec.Fps;
elseif strcmp(approach, 'nearestVal')
    nearestPipelineI = nan;
    nearestPipelineI(1) = round(pipelineFrames) / DSetSpec.Fps;
else
    error('Unrecognised setting.')
end

% Do we need to interpolate?
if length(nearestPipelineI) == 2
    if nearestPipelineI(2) == nearestPipelineI(1)
        % Actually no need to interpolate
        nearestPipelineI = nearestPipelineI(1);
    else
        weight = (pipelineI - nearestPipelineI(1)) ...
            / (nearestPipelineI(2) - nearestPipelineI(1));
    end
end

% Evaluate at the points
numEvals = length(nearestPipelineI);
nearestTrialLLs = NaN(length(Data.Resp), numEvals);
nearestEvQual = NaN(length(Data.Resp), numEvals);

for iEval = 1 : numEvals
    nearestPipeIdx = iEval;
    
    TempParamStruct = ParamStruct;
    TempParamStruct.PipelineI = nearestPipelineI(nearestPipeIdx);
    
    [nearestTrialLLs(:, iEval), nearestEvQual(:, iEval)] = ...
        cm_computeLikeliAtIntegerPipe(model, ...
        findIncludedTrials, TempParamStruct, Data, DSetSpec);
end

% Interpolate
if length(nearestPipelineI) == 2
    trialLL = (nearestTrialLLs(:, 1)*(1-weight)) ...
        + (nearestTrialLLs(:, 2)*weight);
    estEvQual = (nearestEvQual(:, 1)*(1-weight)) ...
        + (nearestEvQual(:, 2)*weight);
elseif length(nearestPipelineI) == 1
    trialLL = nan(size(nearestTrialLLs, 1), 1);
    trialLL(:) = nearestTrialLLs(:, 1);
    
    estEvQual = nan(size(nearestEvQual, 1), 1);
    estEvQual(:) = nearestEvQual(:, 1);
else
    error('Bug')
end

% Check 
if any(isnan(trialLL(findIncludedTrials(Data)))); error('Bug'); end




