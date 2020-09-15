function wlPlot_plotMatrixErrorStats(cfg, serieslist, figtitle, filelabel)

% function wlPlot_plotMatrixErrorStats(cfg, serieslist, figtitle, filelabel)
%
% This function creates bar plots and scatter-plots of specified error
% metrics for a specified series of event matrices.
%
% Bar plots show a histogram of event counts in each error value bin.
% Scatter plots show error values vs event frequency, amplitude, duration,
% and signal-to-noise ratio.
%
% "cfg" contains figure configuration information (per FIGCONFIG.txt).
% "serieslist" is an array of structures with the following fields:
%   "evmatrix":  The event matrix to plot.
%   "errfield":  The field name within (event).auxdata with the error value.
%   "legend":  The label to apply to this data series in the plot legend.
%   "color" [r g b]:  The color to use for this data series in the plot.
% "figtitle" is the title to apply to the figure. Additional text is appended.
% "figlabel" is used within figure filenames to identify this figure.


%
% Configuration
% FIXME - Perhaps break this out into "figconfig" fields?

useerrorbars = false;
symbolerror = 'o';
%symbolpoint = '+';
symbolpoint = '.';

% Size of error histogram bins. This is in the log10 domain.
binwidth = 0.05;


% FIXME - Count the number of events, and tweak configuration if there's
% a large number.

if false
  evcount = 0;
  for sidx = 1:length(serieslist)
    evcount = evcount + wlAux_getMatrixEventCount(serieslist(sidx).evmatrix);
  end

  if 100 < evcount
    symbolpoint = '.';
  end
end


%
% First pass: Consolidate information to plot.

rangefreq = [ inf -inf ];
rangeamp = [ inf -inf ];
rangedur = [ inf -inf ];
rangesnr = [ inf -inf ];
rangeerr = [ inf -inf ];

for sidx = 1:length(serieslist)

  thismat = serieslist(sidx).evmatrix;
  thisfname = serieslist(sidx).errfield;

  [ bandcount trialcount chancount ] = size(thismat.events);

  thisfmean = [];
  thisfdev = [];
  thisamean = [];
  thisadev = [];
  thisdur = [];
  thissnr = [];
  thiserr = [];

  dcount = 0;

  for bidx = 1:bandcount
    for tidx = 1:trialcount
      for cidx = 1:chancount
        thisevlist = thismat.events{bidx, tidx, cidx};
        for eidx = 1:length(thisevlist)

          thisev = thisevlist(eidx);
          dcount = dcount + 1;

          % FIXME - Just use nominal parameters, rather than instantaneous.

          thisfmean(dcount) = mean([ thisev.f1 thisev.f2 ]);
          thisfdev(dcount) = std([ thisev.f1 thisev.f2 ]);

          thisamean(dcount) = mean([ thisev.a1 thisev.a2 ]);
          thisadev(dcount) = std([ thisev.a1 thisev.a2 ]);

          thisdur(dcount) = thisev.duration;

          thissnr(dcount) = thisev.snr;

          thiserr(dcount) = getfield(thisev.auxdata, thisfname);

        end
      end
    end
  end

% FIXME - Diagnostics.
%disp(sprintf('.. %s - series %d - %d events', filelabel, sidx, dcount));

  chartfmean{sidx} = thisfmean;
  chartfdev{sidx} = thisfdev;
  chartamean{sidx} = thisamean;
  chartadev{sidx} = thisadev;
  chartdur{sidx} = thisdur;
  chartsnr{sidx} = thissnr;
  charterr{sidx} = thiserr;
  chartzero{sidx} = 0 * thiserr;

  rangefreq(1) = min([ rangefreq(1) min(thisfmean) ]);
  rangefreq(2) = max([ rangefreq(2) max(thisfmean) ]);
  rangeamp(1) = min([ rangeamp(1) min(thisamean) ]);
  rangeamp(2) = max([ rangeamp(2) max(thisamean) ]);
  rangedur(1) = min([ rangedur(1) min(thisdur) ]);
  rangedur(2) = max([ rangedur(2) max(thisdur) ]);
  rangesnr(1) = min([ rangesnr(1) min(thissnr) ]);
  rangesnr(2) = max([ rangesnr(2) max(thissnr) ]);
  rangeerr(1) = min([ rangeerr(1) min(thiserr) ]);
  rangeerr(2) = max([ rangeerr(2) max(thiserr) ]);

end

% Pad the ranges a bit.

rangefreq = [ 0.66 * rangefreq(1), 1.5 * rangefreq(2) ];
rangeamp = [ 0.66 * rangeamp(1), 1.5 * rangeamp(2) ];
rangedur = [ 0.66 * rangedur(1), 1.5 * rangedur(2) ];
rangeerr = [ 0.66 * rangeerr(1), 1.5 * rangeerr(2) ];


%
% Second pass: Generate the plots.

figure(cfg.fig)


%
% Frequency.

clf('reset');
hold on;

for sidx = 1:length(chartfmean)
  if useerrorbars
    % NOTE - It's X, Y, _Y-_, _Y+_, _X-_, _X+_.
    errorbar( chartfmean{sidx}, charterr{sidx}, ...
      chartzero{sidx}, chartzero{sidx}, ...
      chartfdev{sidx}, chartfdev{sidx}, ...
      symbolerror, 'Color', serieslist(sidx).color, ...
      'Displayname', serieslist(sidx).legend );
  else
    % NOTE - It's X, Y, size list, colour list.
    % An empty list uses default size, and a single colour works.
    scatter( chartfmean{sidx}, charterr{sidx}, ...
      [], serieslist(sidx).color, symbolpoint, ...
      'Displayname', serieslist(sidx).legend );
  end
end

hold off;

xlabel('Frequency (Hz)');
xlim(rangefreq);
set(gca, 'Xscale', 'log');

ylabel('Relative Error');
ylim(rangeerr);
set(gca, 'Yscale', 'log');

legend('show', 'Location', 'northeast');

title( sprintf('%s - vs Frequency', figtitle) );
saveas( cfg.fig, sprintf('%s/err-freq-%s.png', cfg.outdir, filelabel) );


%
% Amplitude.

clf('reset');
hold on;

for sidx = 1:length(chartamean)
  if useerrorbars
    % NOTE - It's X, Y, _Y-_, _Y+_, _X-_, _X+_.
    errorbar( chartamean{sidx}, charterr{sidx}, ...
      chartzero{sidx}, chartzero{sidx}, ...
      chartadev{sidx}, chartadev{sidx}, ...
      symbolerror, 'Color', serieslist(sidx).color, ...
      'Displayname', serieslist(sidx).legend );
  else
    % NOTE - It's X, Y, size list, colour list.
    % An empty list uses default size, and a single colour works.
    scatter( chartamean{sidx}, charterr{sidx}, ...
      [], serieslist(sidx).color, symbolpoint, ...
      'Displayname', serieslist(sidx).legend );
  end
end

hold off;

xlabel('Amplitude (a.u.)');
xlim(rangeamp);
set(gca, 'Xscale', 'log');

ylabel('Relative Error');
ylim(rangeerr);
set(gca, 'Yscale', 'log');

legend('show', 'Location', 'northeast');

title( sprintf('%s - vs Amplitude', figtitle) );
saveas( cfg.fig, sprintf('%s/err-amp-%s.png', cfg.outdir, filelabel) );


%
% Duration.

clf('reset');
hold on;

for sidx = 1:length(chartdur)
  if useerrorbars
    % NOTE - It's X, Y, _Y-_, _Y+_, _X-_, _X+_.
    errorbar( chartdur{sidx}, charterr{sidx}, ...
      chartzero{sidx}, chartzero{sidx}, ...
      chartzero{sidx}, chartzero{sidx}, ...
      symbolerror, 'Color', serieslist(sidx).color, ...
      'Displayname', serieslist(sidx).legend );
  else
    % NOTE - It's X, Y, size list, colour list.
    % An empty list uses default size, and a single colour works.
    scatter( chartdur{sidx}, charterr{sidx}, ...
      [], serieslist(sidx).color, symbolpoint, ...
      'Displayname', serieslist(sidx).legend );
  end
end

hold off;

xlabel('Duration (s)');
xlim(rangedur);
set(gca, 'Xscale', 'log');

ylabel('Relative Error');
ylim(rangeerr);
set(gca, 'Yscale', 'log');

legend('show', 'Location', 'northeast');

title( sprintf('%s - vs Duration', figtitle) );
saveas( cfg.fig, sprintf('%s/err-dur-%s.png', cfg.outdir, filelabel) );


%
% SNR.

clf('reset');
hold on;

for sidx = 1:length(chartsnr)
  if useerrorbars
    % NOTE - It's X, Y, _Y-_, _Y+_, _X-_, _X+_.
    errorbar( chartsnr{sidx}, charterr{sidx}, ...
      chartzero{sidx}, chartzero{sidx}, ...
      chartzero{sidx}, chartzero{sidx}, ...
      symbolerror, 'Color', serieslist(sidx).color, ...
      'Displayname', serieslist(sidx).legend );
  else
    % NOTE - It's X, Y, size list, colour list.
    % An empty list uses default size, and a single colour works.
    scatter( chartsnr{sidx}, charterr{sidx}, ...
      [], serieslist(sidx).color, symbolpoint, ...
      'Displayname', serieslist(sidx).legend );
  end
end

hold off;

xlabel('Signal to Noise Ratio (dB)');
xlim(rangesnr);
% SNR is in dB, which is already a log scale.
set(gca, 'Xscale', 'linear');

ylabel('Relative Error');
ylim(rangeerr);
set(gca, 'Yscale', 'log');

legend('show', 'Location', 'northeast');

title( sprintf('%s - vs SNR', figtitle) );
saveas( cfg.fig, sprintf('%s/err-snr-%s.png', cfg.outdir, filelabel) );


%
% Histogram.


% FIXME - Doing this the quick and dirty way (trusting "histogram").
% NOTE - We need to explicitly convert to the log domain, since it doesn't
% have an option for that.

clf('reset');
hold on;

for sidx = 1:length(charterr)
  thisdata = charterr{sidx};
  thisdata = log10(thisdata);
  histogram(thisdata, 'FaceColor', serieslist(sidx).color, ...
    'BinWidth', binwidth, ...
    'Displayname', serieslist(sidx).legend);
end

hold off;

xlabel('Relative Error (log10)');
%xlim(rangeerr);
%set(gca, 'Xscale', 'linear');

ylabel('Event Count');
%ylim(rangeerr);
%set(gca, 'Yscale', 'log');

legend('show', 'Location', 'northwest');

title( sprintf('%s - Histogram', figtitle) );
saveas( cfg.fig, sprintf('%s/err-hist-%s.png', cfg.outdir, filelabel) );


%
% Done.

end


%
%
% This is the end of the file.
