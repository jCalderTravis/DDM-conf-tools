function adjustedPipe = computeAdjuedtedPipeTime(DSetSpec, Data, ...
    freeTrials, ParamStruct)
% We treat the small amount of time between a response and the clearing of the 
% frame of the response seperately. Find it... and compute the adjusted pipeline
% duration

clearTime = Data.ActualDurationPrec(freeTrials) - Data.RtPrec(freeTrials);
if any(clearTime > (1/DSetSpec.Fps))
    error('Clear time should not be greater than duration of a frame.')
end
assert(all(clearTime >= 0))
adjustedPipe = ParamStruct.PipelineI + clearTime;