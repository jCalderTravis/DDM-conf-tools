function [totalPreRespEv, allLagMeanPreDecEv, allLagPipeEv, ...
    totalPostRespEv, totalPreSquared] ...
    = preComputePreAndPipeEvidence(DSetSpec, Data)
% Compute various summary statistics of the evidence stream, assuming a range of
% hypothesised pipeline lengths (lags).

% INPUT
% DSetSpec  'DSet.Spec'. Should have a frames per second (Fps) field
% Data      DSet.P(iPtpnt)

% OUTPUT
% totalPreRespEv  [num trials] long vector of total evidence presented prior to a
%           response
% allLagMeanPreDecEv
%           [num trials x hypothesised pipeline lengths] array representing
%           average evidence, predecision, at a range of hypothesised
%           pipeline lengths. If the hypothesised pipeline length is, 
%           e.g., I = 0.2s, then the relevant column of the output
%           matricies is: round(PipelineI*DSetSpec.Fps)+1 
% allLagPipeEv
%           Same as 'AllLagMeanPreDecEv' except represents total pipeline
%           evidence presented.
% totalPostRespEv: All evidence presented following a response. Together with
%           totalPreRespEv, gives total evidence for the whole trial.
% totalPreSquared: The sum of sqaured evidence prior to a decision, divided 
%           by the duration of a frame, in the same format as
%           allLagMeanPreDecEv.


% Input checks
if length(Data) ~= 1; error('Input must be data for one participant'); end
if DSetSpec.TimeUnit ~= 1; error('Data must use seconds as the time unit'); end
if DSetSpec.Fps ~= 20; error('Script assumes 50ms frames'); end
if size(Data.Resp, 2) ~= 1
    error('Script assumes this argument is a column vector')
end

% We want to create a new dotsDiff array in which, for each row, the first
% entry, is the dotsDiff at decsion time (t_D), and the second
% entry is the dotsDiff entry at t_D -1 frame, and so on. So that it represents
% the evidence shown in the frames leading up to the decision. Also want the
% total post response evidence.
lockedFlippedDotsDiff = NaN(size(Data.DotsDiff));
totalPreSquared = NaN(size(Data.DotsDiff));
totalPostRespEv = NaN(size(Data.Resp));

% Find the response frames
respFrame = ceil(Data.RtPrec * DSetSpec.Fps);

% Find the total number of frames presented
totalFrames = round(Data.ActualDurationPrec .* DSetSpec.Fps);

for iRow = 1 : size(Data.DotsDiff, 1)
    
    % Skip trials without valid confidence reports
    if isnan(Data.Conf(iRow)); continue; end
    
    lockedFlippedDotsDiff(iRow, 1 : respFrame(iRow)) = ...
        Data.DotsDiff(iRow, respFrame(iRow) : -1 : 1);
    
    totalPostRespEv(iRow) ...
        = sum(Data.DotsDiff(iRow, (respFrame(iRow)+1):totalFrames(iRow)));
    
    % Squared evidence
    cumulativeDotsSquared = cumsum(Data.DotsDiff(iRow, :).^2);
    totalPreSquared(iRow, 1 : respFrame(iRow)) ...
        = cumulativeDotsSquared(respFrame(iRow) : -1 : 1);
    
    % Defensive programming: In free response blocks the response should always
    % be made during evidence presentation.
    if (Data.BlockType(iRow) == 1) && isnan(Data.DotsDiff(iRow, respFrame(iRow)))
        error('Bug')
    end
end

% We want to change units (see derivations)
totalPreSquared = totalPreSquared * DSetSpec.Fps;

% We can now compute total pipeline evidence at all the lags
lockedFlippedDotsDiff = ...
    [zeros(size(lockedFlippedDotsDiff, 1), 1), lockedFlippedDotsDiff];

allLagPipeEv = cumsum(lockedFlippedDotsDiff, 2);

% What was the total evidence presented prior to response?
totalPreRespEv = nansum(lockedFlippedDotsDiff, 2);

% We know that predecision evidence equals total evidence minus pipeline
% evidence.
allLagPreDecisionEvidence = totalPreRespEv - allLagPipeEv;

% To find average predecision evidence we also need to compute the decision
% time, at each hypothesised pipeline duration.
% Produce an array of the same size as the two outputs (
% [num trials x hypothesised pipeline lengths]) with each column specifying
% the decision time under the hypothesised pipeline duration
hypothesisedPipeline = 0 : 1/DSetSpec.Fps : ...
    ((1/DSetSpec.Fps) * size(Data.DotsDiff, 2));
hypothesisedPipeline = repmat(hypothesisedPipeline, size(Data.DotsDiff, 1), 1);

decisionTime = round(respFrame/DSetSpec.Fps, 10) - ...
    round(hypothesisedPipeline, 10);
% Rounding here as was having floating point arithmatic errors

decisionTime(decisionTime < 0) = NaN;

% We can now compute average predecision evidence at all lags
allLagMeanPreDecEv = ...
    allLagPreDecisionEvidence ./ decisionTime;

% Set mean predecision and pre decision squared to zero if non-decision time 
% is as long as the response time
validTrials = ~((respFrame < 0) | isnan(respFrame));
trialsVector = [1:length(respFrame)]';

respIndicies = sub2ind(size(allLagMeanPreDecEv), trialsVector(validTrials), ...
    (respFrame(validTrials)+1));
allLagMeanPreDecEv(respIndicies) = 0 ;

respIndicies = sub2ind(size(totalPreSquared), trialsVector(validTrials), ...
    (respFrame(validTrials)+1));
totalPreSquared(respIndicies) = 0;








