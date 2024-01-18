function [hiMean, loMean] = drawStimFromUsedStimuli(PtpntData)
% Draw a stimulus from the used stimuli

numTrials = length(PtpntData.Resp);

selectedTrial = randi(numTrials, 1);

hiMean = PtpntData.Ref(selectedTrial) + (PtpntData.Diff(selectedTrial)/2);
loMean = PtpntData.Ref(selectedTrial) - (PtpntData.Diff(selectedTrial)/2);

end