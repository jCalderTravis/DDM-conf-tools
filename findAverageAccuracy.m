function overallAcc = findAverageAccuracy(DSet)
% Find the average accuracy across participants seperately for each block
% type

% Find the number of block types used in the experiment and check this is
% the same for all participants
numBlocks = nan(length(DSet.P), 1);
for iP = 1 : length(DSet.P)
   numBlocks(iP) = length(unique(DSet.P(iP).Data.BlockType)); 
end
numBlocks = unique(numBlocks);
assert(length(numBlocks) == 1)

% Find accuracy in each block
overallAcc = nan(numBlocks, 1);
for iBlock = 1 : numBlocks
    ptpntAcc = mT_stackData(DSet.P, ...
        @(St) mean(St.Data.Acc(St.Data.BlockType==iBlock)==1));
    overallAcc(iBlock) = mean(ptpntAcc);
end
       