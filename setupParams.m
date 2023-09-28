function [ParamStruct, gamma, reguMode] = setupParams(model, ...
    ParamStruct, numBlockTypes, DSetSpec)
% All models' predictions can be computed with the same code, by simply not
% allowing some parameters to be free, but rather stipulating them.

% Observer's internal threshold
if strcmp(model(5:8), 'Flat')
    ParamStruct.BoundSlope = 0;
elseif ~strcmp(model(5:8), 'Slpe')
    error('Unknown model specification.')
end

% Drift rate variability
if strcmp(model(9:12), 'None')
    ParamStruct.Sigma_phi = 0;
    
    % We need more parameters if we are in a model where we specify a parameter
    % for each block type
    if strcmp(model(13:16), 'Diff')
        ParamStruct.Sigma_phi = repmat(ParamStruct.Sigma_phi, 1, numBlockTypes);
    end
elseif ~strcmp(model(9:12), 'Dvar')
    error('Unknown model specification.')
end

% Metacognitive noise
if (length(model) < 17) ...
            || strcmp(model(17:20), 'NoMV') 
        ParamStruct.MetacogNoise = 0;
        
        % We need more parameters if we are in a model where we specify a parameter
        % for each block type
        if strcmp(model(13:16), 'Diff')
            ParamStruct.MetacogNoise = repmat(ParamStruct.MetacogNoise, 1, numBlockTypes);
        end
        
elseif ~strcmp(model(17:20), 'Mvar')
        error('Unknown model specification.')
end

% Stimulus noise
if strcmp(model(1:4), 'TrDs') 
    % Set assumed noise ratio to the true value
    sigma_stim = findSigmaStim(DSetSpec);
    sigmaSqd_drfit = (DSetSpec.AvEvidence.^2) * (ParamStruct.Sigma_phi.^2);
    
    gamma = sigmaSqd_drfit ...
        / ((ParamStruct.Sigma_acc.^2) + (sigma_stim.^2) + sigmaSqd_drfit);
    
    % We need more parameters if we are in a model where we specify a parameter
    % for each block type
    if strcmp(model(13:16), 'Diff')
        gamma = repmat(gamma, 1, numBlockTypes);
        
    end
    
elseif strcmp(model(1:4), 'NDsc')
    
    % Set to no discounting
    gamma = 0;
    
    % We need more parameters if we are in a model where we specify a parameter
    % for each block type
    if strcmp(model(13:16), 'Diff')
        gamma = repmat(gamma, 1, numBlockTypes);
        
    end

elseif strcmp(model(1:4), 'FaDs')
    
    % Convert from log ratio, to the format used here
    gamma = ParamStruct.NoiseRatio;
    gamma = exp(gamma);
    gamma = 1 ./ (1 + (1./gamma));
    
    if strcmp(model(13:16), 'Diff')
        error('Not coded up yet')
    end
else
    error('Unknown model specification.') 
end

% Incorrect generative
if (length(model) > 24)
    error('Unknown model specification.')    
end


% Same or different parameters for the different block types?
if strcmp(model(13:16), 'Same')
    
    fieldsNames = fieldnames(ParamStruct);
    
    % We ignore paramters here, which are only used in the forced response
    % model
    fieldsNames = setdiff(fieldsNames, {'BoundSlope', 'BoundIntercept', 'PipelineI'});
    
    for iParam = 1 : length(fieldsNames)
        
        % Check that only one parameter for both conditions has been provided
        if size(ParamStruct.(fieldsNames{iParam}), 2) ~= 1; error('Bug'); end
        
        % Set the parameter to be the same for all block types        
        ParamStruct.(fieldsNames{iParam}) = ...
            repmat(ParamStruct.(fieldsNames{iParam}), 1, numBlockTypes);
    end
    
    % Also need to do this for noiseRatio
    gamma = [gamma, gamma];
        
elseif ~strcmp(model(13:16), 'Diff')
    error('Unknown model specification.')
end


% Regularisation
if (length(model) < 21) ...
            || strcmp(model(21:24), 'NoRg') 
    reguMode = 'NoRg';
        
elseif strcmp(model(21:24), 'Reg1')
    reguMode = 'Reg1';
    
elseif strcmp(model(21:24), 'Reg2')
    reguMode = 'Reg2';
else
    error('Unknown model specification.')
end


