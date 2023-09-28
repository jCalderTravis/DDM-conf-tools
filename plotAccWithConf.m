function figHandle = plotAccWithConf(DSet, plotType, confType, wideAxis, varargin) 

% INPUT
% confType: 'raw' or 'binned'
% wideAxis: If set to true, then axes cover range [0, 1] for confidence and acc
% varargin: Figure handle to plot onto 
% varargin{2}: scalar. Number of bins to use for plotting. Only used if
%   confType is raw.

if isempty(varargin)
    figureHandle = figure;
else
    figureHandle = varargin{1};
end

if (length(varargin) > 1) && (~isempty(varargin{2}))
    numBins = varargin{2};
else
    numBins = 10;
end

if strcmp(confType, 'binned')
    XVars.ProduceVar = @(Strcut) Strcut.ConfCat;
    XVars.NumBins = 'prebinned';
elseif strcmp(confType, 'raw')
    XVars.ProduceVar = @(Strcut) Strcut.Conf;
    XVars.NumBins = numBins;
else
    error('Unknown input')
end

YVars.ProduceVar = @(Strcut, incTrials) mean(Strcut.Acc(incTrials));
YVars.FindIncludedTrials = @(Struct) ~isnan(Struct.Conf);

Series(1).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 0;
Series(2).FindIncludedTrials = @(Struct) Struct.IsForcedResp == 1;

PlotStyle.Data(1).Colour = mT_pickColour(1);
PlotStyle.Data(2).Colour = mT_pickColour(4);

PlotStyle.General = 'paper';

PlotStyle.Data(1).Name = 'Free response';
PlotStyle.Data(2).Name = 'Interrogation';

PlotStyle.Data(1).PlotType = plotType;
PlotStyle.Data(2).PlotType = plotType;

if strcmp(confType, 'binned')
    PlotStyle.Xaxis.Title = 'Binned confidence';
    PlotStyle.Xaxis.Ticks = [1 2 3 4];
    PlotStyle.Xaxis.Lims = [0.8, 4.2];
elseif strcmp(confType, 'raw')
    PlotStyle.Xaxis.Title = 'Confidence';
end

PlotStyle.Yaxis.Title = 'Accuracy';
PlotStyle.Yaxis.Ticks = linspace(0.5, 1, 6);

% Overide defaults if requested
if wideAxis
PlotStyle.Xaxis.Ticks = [0, 0.25, 0.5, 0.75, 1];
PlotStyle.Xaxis.InvisibleTickLablels = [];
PlotStyle.Yaxis.Ticks = [0, 0.25, 0.5, 0.75, 1];
end
    
figHandle = mT_plotVariableRelations(DSet, XVars, YVars, Series, ...
    PlotStyle, figureHandle);

if strcmp(confType, 'raw')
    refHandle = refline(1, 0);
    refHandle.LineStyle = '--';
    refHandle.Color = [0.4 0.4 0.4];
end
