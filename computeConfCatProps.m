function CatProp = computeConfCatProps(Data, expectedBins)
% Computes the propotion of values falling into each confidence category, seperately
% for different responses.

% INPUT
% Data: DSet.P(i).Data, ConfCat must be coded as an integer
% expectedBins: The expected number of confidence bins

% OUTPUT
% CatProps: [numBlockTypes] long cell array. Each field contains the data for
% one blocktype in a [num categories x response] array. Summing along the first
% dimention, leads to a row of ones.


% How many blocks are there?
blockTypes = unique(Data.BlockType);
blockTypes(isnan(blockTypes)) = [];

% How many confidence bins are there?
confBins = unique(Data.ConfCat);
confBins(isnan(confBins)) = [];

if length(confBins) ~= expectedBins; error('Bug'); end

CatProp = cell(length(blockTypes), 1);

for iBlock = 1 : length(blockTypes)
    
    % How many response options are there?
    response = unique(Data.Resp);
    response(isnan(response)) = [];
    
    CatProp{iBlock} = NaN(length(confBins), length(response));
    
    for iResp = 1 : length(response)
        validTrials = (Data.Resp == response(iResp)) & ~isnan(Data.Conf);
        
        for iBin = 1 : length(confBins)
            CatProp{iBlock}(iBin, iResp) ...
                = sum((Data.ConfCat == confBins(iBin)) ...
                & (Data.Resp == response(iResp))) /...
                sum(validTrials); 
        end    
    end
    
    if any(round(sum(CatProp{iBlock}), 4) ~= 1); error('Bug'); end
end
    