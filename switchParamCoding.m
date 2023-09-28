function output = switchParamCoding(model, PtpntData, input, destination, varargin)
% Change the way parameters are formated so that they are read for either the
% main modelling functions, or for the simulation functions

% INPUT
% model: (Only needed in 'simulation' direction. See 'destination'.) The 
%   current model name.
% PtpntData: (Only needed in 'simulation' direction. See 'destination'.) 
%   DSet.P(i).Data for one participant
% input: Either a ParamStruct (ready for use in cm_computeLL), or a
%   Settings struct (ready for use in the simDecisAndConf functions)
% destination: Convert to a 'modelling' ParamStruct, or a 'simulation' 
%   Settings struct?
% varargin{1}: Number. If provided, specifies a deadline in the free response
%   condition, after which the decision threshold drops to a very small 
%   value. Only used in the 'simulation' direction.

% NOTES
% In direction 'simulation', the following settings are not set by this
% function and must be additionally set before simulating data:
% TotalTrials, BlockSize, Fps, NumPtpnts, Dots. (See simulateDataSet.m)

if ~isempty(varargin)
    deadline = varargin{1};
else
    deadline = [];
end

if strcmp(destination, 'simulation')
    
    ParamStruct = input;
    
    Settings.DeltaT = 0.0001;
    Settings.Units = 1;
    Settings.IndDriftSD = 0;
    
    Settings.NoiseSD = ParamStruct.Sigma_acc;
    Settings.StimPropNoiseSD = 0;
    
    if strcmp(model(9:12), 'Dvar')
        Settings.DriftSD = ParamStruct.Sigma_phi;
    elseif strcmp(model(9:12), 'None')
        Settings.DriftSD = 0;
    else
        error('Bug')
    end
    
    boundIntercept = ParamStruct.BoundIntercept;
    
    if strcmp(model(5:8), 'Slpe')
        boundSlope = -ParamStruct.BoundSlope;
    elseif strcmp(model(5:8), 'Flat')
        boundSlope = 0;
    else
        error('Bug')
    end
    
    Settings.ThreshIntercept = boundIntercept;
    Settings.ThreshSlope = boundSlope;
    
    if isempty(deadline)
        Settings.Threshold = @(simTime, blockType) threshold_linear(...
            simTime, blockType, ...
            [boundIntercept, Inf], ...
            [boundSlope, 0]);
    else
        Settings.Threshold = @(simTime, blockType) ...
            threshold_linear_withDeadline(simTime, blockType, ...
            [boundIntercept, Inf], [boundSlope, 0], deadline);
    end
    
    Settings.OverallCommitDelay = ParamStruct.PipelineI;
    Settings.CommitDelaySD = 0;
    Settings.WithinPtCommitDelaySD = 0;
    Settings.SeperateConf = false;
    Settings.ConfCalc = model(1:4);
    Settings.ConfNoiseSd = ParamStruct.MetacogNoise;
    Settings.RandRtLapseRate = 0;
    Settings.MappingLapseRate = 0;
    Settings.ConfLapseRate = ParamStruct.LapseRate;
    Settings.PermitCoM = true;
    Settings.RngSeed = 'random';
    Settings.StimLambda = 1;
    Settings.StimPropNoiseSD = 0;
    Settings.RespLapseRate = 0;
    Settings.PosConfWeight = 1;
    
    if strcmp(model(1:4), 'FaDs')
        Settings.ObserverNoiseRatio = ParamStruct.NoiseRatio;
    elseif (strcmp(model(1:4), 'NDsc') || ...
            strcmp(model(1:4), 'TrDs'))
        Settings.ObserverNoiseRatio = NaN;
    else
        error('Unknown model')
    end
    
    generatingDotDist = @() drawStimFromUsedStimuli(PtpntData);
    
    BlockSettings(1).DotDist = generatingDotDist;
    BlockSettings(1).MaxDuration = @()Inf;
    BlockSettings(1).Type = 'free';
    BlockSettings(1).StimAfterResp = 0;
    BlockSettings(1).ConfAccumulationTime = Inf;
    BlockSettings(1).ForcedEarlyRespProb = {};
    BlockSettings(1).ReversePulse = false;
    
    BlockSettings(2).DotDist = generatingDotDist;
    
    realTrialDurations = PtpntData.PlannedDuration(PtpntData.BlockType == 2);
    
    BlockSettings(2).MaxDuration ...
        = @()datasample(realTrialDurations, 1); 
    BlockSettings(2).Type = 'forced';
    BlockSettings(2).StimAfterResp = 0;
    BlockSettings(2).ConfAccumulationTime = Inf;
    BlockSettings(2).ForcedEarlyRespProb = 0;
    BlockSettings(2).ReversePulse = false;
    
    Settings.BlockSettings = BlockSettings;
    
    output = Settings;
    
elseif strcmp(destination, 'modelling')
    
    Settings = input;
    
    ParamStruct.Sigma_acc = Settings.NoiseSD;
    ParamStruct.Sigma_phi = Settings.DriftSD;
    ParamStruct.BoundIntercept = Settings.ThreshIntercept(1);
    ParamStruct.BoundSlope = -Settings.ThreshSlope(1);
    ParamStruct.PipelineI = Settings.OverallCommitDelay;
    ParamStruct.MetacogNoise = Settings.ConfNoiseSd;
    ParamStruct.LapseRate = Settings.ConfLapseRate;
    ParamStruct.NoiseRatio = Settings.ObserverNoiseRatio;
    
    output = ParamStruct;
    
end

