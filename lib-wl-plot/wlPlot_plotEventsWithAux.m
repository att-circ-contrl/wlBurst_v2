function wlPlot_plotEventsWithAux(cfg, evlist, evstride, ...
  topcurves, midcurves, botcurves, figtitle, filelabel)

% function wlPlot_plotEventsWithAux(cfg, evlist, evstride, ...
%   topcurves, midcurves, botcurves, figtitle, filelabel)
%
% This function plots a series of events, making three-pane plots with
% selected "auxwaves" curves in each pane.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "evlist" is a list of event records, in the form used by traceAddBursts().
% "evstride" suppresses plots; one out of every "evstride" events is plotted.
% "topcurves", "midcurves", and "botcurves" are cell arrays describing pane
%   contents. The first element is the pane's subtitle prefix; remaining
%   elements are "auxwaves" curve labels for time series and data series
%   followed by plotting colours (RGB triplets), in the order in which the
%   curves are to be plotted.
% "figtitle" is the title to apply to the figure. Subfigures have a prefix
%   prepended to this title. The event number is appended.
% "filelabel" is used within the figure filename to identify this figure.

for eidx = 1:evstride:length(evlist)

  thisev = evlist(eidx);


  % Build wave lists.

  toplabel = topcurves{1};
  midlabel = midcurves{1};
  botlabel = botcurves{1};


  sigcount = 0;

  for cidx = 2:3:length(topcurves)
    sigcount = sigcount + 1;
    topsigs(sigcount) = struct( ...
      'times', getfield(thisev.auxwaves, topcurves{cidx}), ...
      'data', getfield(thisev.auxwaves, topcurves{cidx + 1}), ...
      'color', getfield(thisev.auxwaves, topcurves{cidx + 2}) );
  end

  if 1 > sigcount
    topsigs = [];
  end


  sigcount = 0;

  for cidx = 2:3:length(midcurves)
    sigcount = sigcount + 1;
    midsigs(sigcount) = struct( ...
      'times', getfield(thisev.auxwaves, midcurves{cidx}), ...
      'data', getfield(thisev.auxwaves, midcurves{cidx + 1}), ...
      'color', getfield(thisev.auxwaves, midcurves{cidx + 2}) );
  end

  if 1 > sigcount
    midsigs = [];
  end


  sigcount = 0;

  for cidx = 2:3:length(botcurves)
    sigcount = sigcount + 1;
    botsigs(sigcount) = struct( ...
      'times', getfield(thisev.auxwaves, botcurves{cidx}), ...
      'data', getfield(thisev.auxwaves, botcurves{cidx + 1}), ...
      'color', getfield(thisev.auxwaves, botcurves{cidx + 2}) );
  end

  if 1 > sigcount
    botsigs = [];
  end



  % Build this figure.

% FIXME - NYI.
%  wlPlot_plotTriplePane( cfg, ...
  wlPlot_plotMultipleExtracted( cfg, ...
    topsigs, midsigs, botsigs, ...
    sprintf('%s - Event %04d', figtitle, eidx), ...
    sprintf('%s-%04d', filelabel, eidx) );


end  % Event iteration.


%
% Done.

end  % Function.

%
% This is the end of the file.
