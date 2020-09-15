function wlPlot_plotEventXYMultiDual(cfg, matchseries, ...
  freqrange, durrange, amprange, figtitle, filelabel)

% function wlPlot_plotEventXYMultiDual(cfg, matchseries, ...
%   freqrange, durrange, amprange, figtitle, filelabel)
%
% This function makes a scatter-plot of detected parameter values vs
% ground-truth parameter values for frequency, duration, and amplitude.
%
% This function differs from wlPlot_plotEventXYMulti in that two event
% lists are provided, rather that one list containing event pairs.
%
% Plotted frequency and amplitude are the arithmetic means of the
% instantaneous frequency and amplitude curves in the event records.
% Error bars for these values are shown.
%
% "cfg" contains figure configuration information (see FIGCONFIG.txt").
% "matchseries" is an array of structures with the following fields:
%   "color" [r g b]:  The color to use for this series of records.
%   "legend":  The legend title to use for this series of records.
%   "truthlist":  A [1xN] array of ground truth event records.
%   "testlist":  A [1xN] array of detected event records.
% "freqrange" [min max] defines the frequency range to be plotted (logscale).
% "durrange" [min max] defines the duration range to be plotted (linear).
% "amprange" [min max] defines the amplitude range to be plotted (logscale).
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within figure filenames to identify this figure.


% Merge the two lists.

for sidx = 1:length(matchseries)

  thistruthlist = matchseries(sidx).truthlist;
  thistestlist = matchseries(sidx).testlist;

  evcount = min(length(thistruthlist), length(thistestlist));

  clear mergedlist;

  for eidx = 1:evcount
    mergedlist(eidx) = struct( 'truth', thistruthlist(eidx), ...
      'test', thistestlist(eidx) );
  end

  if 1 > evcount
    mergedlist = [];
  end

  newmatchseries(sidx) = struct( 'matchlist', mergedlist, ...
    'color', matchseries(sidx).color, 'legend', matchseries(sidx).legend );

end


% Call the other version of this function.

wlPlot_plotEventXYMulti(cfg, newmatchseries, ...
  freqrange, durrange, amprange, figtitle, filelabel);


%
% Done.

end

%
% This is the end of the file.
