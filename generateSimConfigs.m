function SimConfig = generateSimConfigs(modelNames, varargin)
% Generates preset configurations for simulating data.

% INPUT
% modelNames: Cell array of names of the models which would like 
% configurations for. See names in script below.
% varargin: Strcuture with any of the fields in the SharedSettings strcuture
% below. The settings below will be replaced. 

% OUTPUT
% SimConfig: Struct array as long as the number of requested configurations.
% Ready to be passed to simulateDataSet once the 'Name' field has been removed.


if ~isempty (varargin)                                                          
    UserSettings = varargin{1};                                                  
else                                                                             
    UserSettings = struct();                                                     
end

% Specify shared settings
bounds = {[2000, Inf], [2000, Inf]};
slope = {[0, 0], [-800, 0]};

SharedSettings.Name = NaN;
SharedSettings.DeltaT = 0.0001;
SharedSettings.Fps = 20;
SharedSettings.SeperateConf = 0;
SharedSettings.PermitCoM = 1;
SharedSettings.RngSeed = 'random';
SharedSettings.TotalTrials = 640;
SharedSettings.BlockSize = 40;
SharedSettings.Units = 1;
SharedSettings.NumPtpnts = 20;
SharedSettings.MappingLapseRate = 0;
SharedSettings.RandRtLapseRate = 0;
SharedSettings.ConfLapseRate = 0;
SharedSettings.OverallCommitDelay = 0.35;
SharedSettings.CommitDelaySD = 0;
SharedSettings.WithinPtCommitDelaySD = 0;
SharedSettings.NoiseSD =  4 * 4 * 40 / ( (0.05)^0.5 );
SharedSettings.Dots.Max = 3096;
SharedSettings.Dots.Min = 0;
SharedSettings.Dots.Sd = 220;
SharedSettings.StimLambda = 1;
SharedSettings.StimPropNoiseSD = 0;
SharedSettings.RespLapseRate = 0;
SharedSettings.PosConfWeight = 1;

BlockSettings(1).DotDist = @()defaultDotDist('forcedExp');
BlockSettings(1).MaxDuration = @()Inf;
BlockSettings(1).Type = 'free';
BlockSettings(1).StimAfterResp = 0;
BlockSettings(1).ConfAccumulationTime = Inf;
BlockSettings(1).ForcedEarlyRespProb = {};
BlockSettings(1).ReversePulse = false;

BlockSettings(2).DotDist = @()defaultDotDist('forcedExp');
BlockSettings(2).MaxDuration = @()defaultForcingDist(0.8, 0.3, 0.2, 4);
BlockSettings(2).Type = 'forced';
BlockSettings(2).StimAfterResp = 0;
BlockSettings(2).ConfAccumulationTime = Inf;
BlockSettings(2).ForcedEarlyRespProb = 0;
BlockSettings(2).ReversePulse = false;

SharedSettings.BlockSettings = BlockSettings;

% Replace default with user chosen settings
fieldsToChange = fieldnames(UserSettings);

for iField = 1 : length(fieldsToChange)
    
    % Bounds and slope are treated differently
    if strcmp(fieldsToChange{iField}, 'bounds')
        % If provided in python, may have been provided as a string
        if ischar(UserSettings.bounds)
            UserSettings.bounds = eval(UserSettings.bounds);
        end
        bounds = UserSettings.bounds;
        continue 
    end
    
    if strcmp(fieldsToChange{iField}, 'slope')
        % If provided in python, may have been provided as a string
        if ischar(UserSettings.slope)
            UserSettings.slope = eval(UserSettings.slope);
        end
        slope = UserSettings.slope;
        continue 
    end

    % Treat all other settings in the same way
    if ~isfield(SharedSettings, fieldsToChange{iField})
        error('Incorrect use of inputs')
    else
        SharedSettings.(fieldsToChange{iField}) ...
            = UserSettings.(fieldsToChange{iField});
    end    
end

SimConfig = repmat(SharedSettings, length(modelNames), 1);

% Specify specific settings
for iModel = 1 : length(modelNames)
    
    thisModelName = modelNames{iModel};
    SimConfig(iModel).Name = thisModelName;
    
    if strcmp(thisModelName(17:20), 'Mvar')
        SimConfig(iModel).ConfNoiseSd = 1500;
    elseif strcmp(thisModelName(17:20), 'NoMV')
        SimConfig(iModel).ConfNoiseSd = 0;
    else
        error('Unknown setting.')
    end
    
    if strcmp(thisModelName(1:4), 'FaDs')
        SimConfig(iModel).ObserverNoiseRatio = 0.9;
        SimConfig(iModel).ConfCalc = 'FaDs';
        
    elseif strcmp(thisModelName(1:4), 'TrDs')
        SimConfig(iModel).ObserverNoiseRatio = NaN;
        SimConfig(iModel).ConfCalc = 'TrDs';
        
    elseif strcmp(thisModelName(1:4), 'NDsc')
        SimConfig(iModel).ObserverNoiseRatio = NaN;
        SimConfig(iModel).ConfCalc = 'NDsc';
        
    else
        error('Unknown setting.')
    end
    
  
    if strcmp(thisModelName(5:8), 'Flat')
        SimConfig(iModel).ThreshIntercept = bounds{1};
        SimConfig(iModel).ThreshSlope = slope{1};
    elseif strcmp(thisModelName(5:8), 'Slpe')
        SimConfig(iModel).ThreshIntercept = bounds{2};
        SimConfig(iModel).ThreshSlope = slope{2};
    else
        error('Unknown setting.')
    end
    
    SimConfig(iModel).Threshold = @(simTime, blockType) ...
        threshold_linear(simTime, blockType, ...
        SimConfig(iModel).ThreshIntercept, ...
        SimConfig(iModel).ThreshSlope);
    
    if strcmp(thisModelName(9:12), 'Dvar')
        SimConfig(iModel).DriftSD = 1;
    elseif strcmp(thisModelName(9:12), 'None')
        SimConfig(iModel).DriftSD = 0;
    else
        error('Unknown setting.')
    end
end







