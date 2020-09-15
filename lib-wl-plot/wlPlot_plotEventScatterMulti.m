function wlPlot_plotEventScatterMulti(cfg, eventseries, ...
  freqrange, durrange, amprange, figtitle, filelabel)

% function wlPlot_plotEventScatterMulti(cfg, eventseries, ...
%   freqrange, durrange, amprange, figtitle, filelabel)
%
% This function makes a scatter-plot of burst amplitudes and burst durations
% (in periods), each as a function of burst frequency.
%
% Plotted frequency and amplitude are the arithmetic means of the
% instantaneous frequency and amplitude curves in the event records.
% Error bars for these values are shown.
%
% "cfg" contains figure configuration information (see FIGCONFIG.txt").
% "eventseries" is an array of structures with the following fields:
%   "eventlist":  A [1xN] array of event records (per wlSynth_traceAddBursts).
%   "color" [r g b]:  The color to use for this series of records.
%   "legend":  The legend title to use for this series of records.
% "freqrange" [min max] defines the frequency range to be plotted (logscale).
% "durrange" [min max] defines the duration range to be plotted (linear).
% "amprange" [min max] defines the amplitude range to be plotted (logscale).
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within figure filenames to identify this figure.


%
% Build mean and standard deviation values for plotted parameters.

for sidx = 1:length(eventseries)

  thisseries = eventseries(sidx).eventlist;

  thisauxseries = struct( 'fmean', [ ], 'fdev', [ ], ...
    'amean', [ ], 'adev', [ ], 'dmean', [ ], 'ddev', [ ] );

  for eidx = 1:length(thisseries)

    thisevent = thisseries(eidx);


    % Default to endpoint parameter values.

    thisfreq = [ thisevent.f1 thisevent.f2 ];
    thismag = [ thisevent.a1 thisevent.a2 ];

    % Extract average instantaneous values if we can.

    if isfield(thisevent, 's1') && isfield(thisevent, 's2') ...
      && isfield(thisevent, 'freq') && isfield(thisevent, 'mag')

      % Average instantaneous parameter values.

      s1 = thisevent.s1;
      s2 = thisevent.s2;

      thisfreq = thisevent.freq(s1:s2);
      thismag = thisevent.mag(s1:s2);

    end


    % Compute statistics to plot.

    thisauxseries.fmean(eidx) = mean(thisfreq);
    thisauxseries.fdev(eidx) = std(thisfreq);

    thisauxseries.amean(eidx) = mean(thismag);
    thisauxseries.adev(eidx) = std(thismag);

    thisauxseries.dmean(eidx) = ...
      thisevent.duration * thisauxseries.fmean(eidx);
    thisauxseries.ddev(eidx) = ...
      thisevent.duration * thisauxseries.fdev(eidx);


    % NOTE - Not touching time/frequency uncertainty here.

  end

  auxseries(sidx) = thisauxseries;

end


%
%
% Plot the resulting data.

%
% Duration vs frequency.

figure(cfg.fig);

clf('reset');

hold on;

for sidx = 1:length(eventseries)

  thisrecord = eventseries(sidx);
  thisauxseries = auxseries(sidx);

  % Remember that it's X, Y, _Yerr-_, _Yerr+_, Xerr-, Xerr+.

  errorbar( thisauxseries.fmean, thisauxseries.dmean, ...
    thisauxseries.ddev, thisauxseries.ddev, ...
    thisauxseries.fdev, thisauxseries.fdev, ...
    'o', 'Color', thisrecord.color, 'Displayname', thisrecord.legend );

end

hold off;

xlabel('Frequency (Hz)');
xlim(freqrange);
set(gca, 'Xscale', 'log');

ylabel('Duration (cycles)');
ylim(durrange);

legend('show');

title( sprintf('%s - Duration', figtitle) );
saveas(cfg.fig, sprintf('%s/evmult-dur-%s.png', cfg.outdir, filelabel));


%
% Amplitude vs frequency.

clf('reset');

hold on;

for sidx = 1:length(eventseries)

  thisrecord = eventseries(sidx);
  thisauxseries = auxseries(sidx);

  % Remember that it's X, Y, _Yerr-_, _Yerr+_, Xerr-, Xerr+.

  errorbar( thisauxseries.fmean, thisauxseries.amean, ...
    thisauxseries.adev, thisauxseries.adev, ...
    thisauxseries.fdev, thisauxseries.fdev, ...
    'o', 'Color', thisrecord.color, 'Displayname', thisrecord.legend );

end

hold off;

xlabel('Frequency (Hz)');
xlim(freqrange);
set(gca, 'Xscale', 'log');

ylabel('Mean Envelope Amplitude (a.u.)');
ylim(amprange);
set(gca, 'Yscale', 'log');

legend('show');

title( sprintf('%s - Amplitude', figtitle) );
saveas(cfg.fig, sprintf('%s/evmult-amp-%s.png', cfg.outdir, filelabel));


%
% Done.

end

%
% This is the end of the file.
