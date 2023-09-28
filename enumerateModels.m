function allModels = enumerateModels(discounting, threshold, driftVar, ...
    shareParams, metacogNoise)
% Creates a cell array containing the names of all models requested

% INPUT
% discounting: Input the forms of discounting want to consider in a cell array.
%   To request all options use {'NDsc', 'TrDs', 'FaDs'}.
% threshold: Input the forms of Threshold want to consider in a cell array.
%   To request all options use {'Flat', 'Slpe'}.
% driftVar: Input the forms of DriftVar want to consider in a cell array.
%   To request all options use {'None', 'Dvar'}.
% shareParams: Fit same params to all blocks, or different params. Input all
%   otpions want. To request all options use {'Same', 'Diff'}.
% metacogNoise: Input the forms of MetacogNoise want to consider in a cell array.
%   To request all options use {'Mvar', 'NoMV'}.

% NOTE
% Will skip models in which true discounting is used and in which there is no
% drift rate variability, as the discounting in this case is just a constant.

allModels = {};

for iDisc = 1 : length(discounting)
   discountTerm = discounting{iDisc};
   
   for iThresh = 1 : length(threshold)
       threshTerm = threshold{iThresh};
       
       for iDrift = 1 : length(driftVar)
           driftTerm = driftVar{iDrift};
           
           for iParams = 1 : length(shareParams)
               paramsTerm = shareParams{iParams};
               
               for iMet = 1 : length(metacogNoise)
                   metTerm = metacogNoise{iMet};
                   
                   % Skip models in which true discounting is used and in 
                   % which there is no drift rate variability, as the 
                   % discounting in this case is just a constant. 
                   if strcmp(discountTerm, 'TrDs') ...
                           && strcmp(driftTerm, 'None')
                       continue 
                   end

                   allModels{end +1, 1} = [discountTerm, threshTerm, driftTerm ...
                       paramsTerm, metTerm];
               end
           end
       end
   end
end
                   
        
   
