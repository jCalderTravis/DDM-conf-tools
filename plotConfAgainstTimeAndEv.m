function figHandle = plotConfAgainstTimeAndEv(DSet, plotType, figHandle, ...
    confType, confVar, evQual, dataset, varargin)
% Make plots of the effect of response time, and the effect of evidence on 
% confidence.

% INPUT
% confType: 'raw' or 'binned'
% confVar: Also plot confidence variance as a y-variable?
% evQual: Also plot evidence quality as a y-variable? (confVar must be on)
% dataset: 'B' for the empirical dataset, 'D' for test of derivations plots
% varargin{1}: String. Set to 'noEv', if do not want to plot the effect of evidence 
% varargin{2}: String. Will be turned into function and used as an inclusion
% condition. Resulting function should accept DSet.P(iP).Data
% varargin{3}: If set to 'median' use median for averaging over participants.
% Otherwise set to 'mean' or don't use (default is 'mean'). Note in the case of
% 'median' error bars still reflect SEM, which doesn't really make sense.
% varargin{4}: scalar. Number of bins to use for plotting. 
% varargin{5}: bool. Split on evidence midpoint (the midpoint between 
%   the two generative means, which itself varied on a trial by trial
%   basis. Default is false.
% varargin{6}: bool. If true, supress any possible subplot lettering. 
%   Default false.

if (~confVar) && evQual; error('Combination not coded'); end 

if (~isempty(varargin)) && (~isempty(varargin{1})) && strcmp(varargin{1}, 'noEv')
    plotEvidence = false;  
else
    plotEvidence = true;  
end

if (length(varargin) > 1) && (~isempty(varargin{2}))
    extraInclusionCond = varargin{2};
else
    extraInclusionCond = 'none';
end

if (length(varargin) > 2) && (~isempty(varargin{3}))
    plotStat = varargin{3};
else
    plotStat = 'mean';
end

if (length(varargin) > 3) && (~isempty(varargin{4}))
    numBins = varargin{4};
else
    numBins = 10;
end

if (length(varargin) > 4) && (~isempty(varargin{5}))
    splitOnEvMid = varargin{5};
else
    splitOnEvMid = false;
end
    
if (length(varargin) > 5) && (~isempty(varargin{6}))
    suppressLetters = varargin{6};
else
    suppressLetters = false;
end

%% Produce required data

% Add negligible noise to RTs to break ties
XVars(1).ProduceVar = @(Data) (Data.RtPrec + (randn(size(Data.RtPrec))*0.00000001));
XVars(1).NumBins = numBins;
if ~strcmp(extraInclusionCond, 'none')
    incFun = str2func(extraInclusionCond);
    XVars(1).FindIncludedTrials = @(Data) incFun(Data);
end

if plotEvidence
    XVars(2).ProduceVar = @(Data) abs(Data.TotalPreRespEv ./ Data.ActualDurationPrec);
    XVars(2).NumBins = numBins;
    if ~strcmp(extraInclusionCond, 'none')
        incFun = str2func(extraInclusionCond);
        XVars(2).FindIncludedTrials = @(Data) incFun(Data);
    end
end

if strcmp(confType, 'raw')
    YVars(1).ProduceVar = @(Data, incTrials) mean(Data.Conf(incTrials));
elseif strcmp(confType, 'binned')
    YVars(1).ProduceVar = @(Data, incTrials) mean(Data.ConfCat(incTrials));
end

if confVar
    if strcmp(confType, 'raw')
        YVars(2).ProduceVar = @(Data, incTrials) var(Data.Conf(incTrials));
    elseif strcmp(confType, 'binned')
        YVars(2).ProduceVar = @(Data, incTrials) var(Data.ConfCat(incTrials));
    end
end

if evQual
    YVars(3).ProduceVar = @(Data, incTrials) mean(Data.EvidenceQual(incTrials));
    YVars(4).ProduceVar = @(Data, incTrials) var(Data.EvidenceQual(incTrials));
end

YVars(1).FindIncludedTrials = @(Data) ~isnan(Data.Conf);
    
if confVar
    YVars(2).FindIncludedTrials = @(Data) ~isnan(Data.Conf);
end

if evQual
    YVars(3).FindIncludedTrials = @(Data) ~isnan(Data.Conf);
    YVars(4).FindIncludedTrials = @(Data) ~isnan(Data.Conf);
end

if strcmp(dataset, 'B')
    PlotStyle.Xaxis(1).Ticks = 0:6;
    PlotStyle.Xaxis(1).InvisibleTickLablels = 2:2:6;
    
    PlotStyle.Xaxis(2).Ticks = 0:1000:6000;
    PlotStyle.Xaxis(2).InvisibleTickLablels = 2:2:6;
    
    if strcmp(confType, 'binned')
        PlotStyle.Yaxis(1).Ticks = linspace(2, 3.2, 7);
        PlotStyle.Yaxis(1).InvisibleTickLablels = [2, 3, 5, 6];
    end
        
    if ~splitOnEvMid
        Series(1).FindIncludedTrials = @(Data) Data.BlockType == 1;
        Series(2).FindIncludedTrials = @(Data) Data.BlockType == 2;
        
        PlotStyle.Data(1).Colour = mT_pickColour(1);
        PlotStyle.Data(2).Colour = mT_pickColour(4);
        
        PlotStyle.Data(1).Name = 'Free response';
        PlotStyle.Data(2).Name = 'Interrogation';
    else
        Series(1).FindIncludedTrials = @(Data) (Data.BlockType == 1) & ...
            (Data.Ref < 1000);
        Series(2).FindIncludedTrials = @(Data) (Data.BlockType == 1) & ...
            (Data.Ref > 1000);
        Series(3).FindIncludedTrials = @(Data) (Data.BlockType == 2) & ...
            (Data.Ref < 1000);
        Series(4).FindIncludedTrials = @(Data) (Data.BlockType == 2) & ...
            (Data.Ref > 1000);
        
        PlotStyle.Data(1).Colour = mT_pickColour(1);
        PlotStyle.Data(2).Colour = mT_pickColour(1)+0.5;
        PlotStyle.Data(3).Colour = mT_pickColour(4);
        PlotStyle.Data(4).Colour = mT_pickColour(4)*1.5;

        PlotStyle.Data(1).Name = 'Free response (low midpoint)';
        PlotStyle.Data(2).Name = 'Free response (high midpoint)';
        PlotStyle.Data(3).Name = 'Interrogation (low midpoint)';
        PlotStyle.Data(4).Name = 'Interrogation (high midpoint)';
    end
    
elseif strcmp(dataset, 'D')
    Series(1).FindIncludedTrials = @(Data) Data.BlockType == 1;
    Series(2).FindIncludedTrials = @(Data) Data.BlockType == 2;
    
    PlotStyle.Data(1).Colour = mT_pickColour(1);
    PlotStyle.Data(2).Colour = mT_pickColour(4);
    
    if splitOnEvMid
        error('Case not coded up')
    end
end

PlotStyle.General = 'paper';

PlotStyle.Xaxis(1).Title = 'Response time (s)';
if plotEvidence; PlotStyle.Xaxis(2).Title = 'Average evidence'; end

if strcmp(confType, 'binned')
    PlotStyle.Yaxis(1).Title = {'Binned confidence'};
else
    PlotStyle.Yaxis(1).Title = 'Confidence (arb. units)';
end

if confVar
    if strcmp(confType, 'binned')
        PlotStyle.Yaxis(2).Title = {'Binned confidence var.'};
    else
        PlotStyle.Yaxis(2).Title = {'Confidence variance',  '(arb. units)'};
    end
    PlotStyle.Yaxis(3).Title = {'Ev qual mean',  '(arb. units)'};
    PlotStyle.Yaxis(4).Title = {'Ev qual var',  '(arb. units)'};
end

for iS = 1 : length(Series)
    PlotStyle.Data(iS).PlotType = plotType;
end

if plotEvidence && (~strcmp(dataset, 'D')) && (~suppressLetters)
    PlotStyle.Annotate(1, 1).Text = 'A';
    PlotStyle.Annotate(1, 2).Text = 'B';
    PlotStyle.Annotate(2, 1).Text = 'C';
    PlotStyle.Annotate(2, 2).Text = 'D';
end


figHandle = mT_plotVariableRelations(DSet, XVars, YVars, Series, ...
    PlotStyle, figHandle, plotStat);
