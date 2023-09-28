function allModels = produceDefaultModelLists(default)
% Function produce a cell array of models for some frequently required
% combinations

% INPUT
% default: 'all' models that have been interested in or just 'key' models.
%   'NoMV' for all key models but without metacognitive noise.

if strcmp(default, 'all')
    
    discounting = {'NDsc', 'TrDs', 'FaDs'};
    threshold = {'Flat', 'Slpe'};
    driftVar = {'None', 'Dvar'};
    shareParams = {'Same'};
    metacogNoise = {'Mvar', 'NoMV'};
    
elseif strcmp(default, 'key')
    
    discounting = {'NDsc', 'TrDs', 'FaDs'};
    threshold = {'Flat', 'Slpe'};
    driftVar = {'None', 'Dvar'};
    shareParams = {'Same'};
    metacogNoise = {'Mvar'};
    
elseif strcmp(default, 'NoMV')
    
    discounting = {'NDsc', 'TrDs', 'FaDs'};
    threshold = {'Flat', 'Slpe'};
    driftVar = {'None', 'Dvar'};
    shareParams = {'Same'};
    metacogNoise = {'NoMV'};    
    
end

allModels = enumerateModels(discounting, threshold, driftVar, ...
    shareParams, metacogNoise);