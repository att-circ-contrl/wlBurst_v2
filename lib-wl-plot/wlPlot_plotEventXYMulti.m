function wlPlot_plotEventXYMulti(cfg, matchseries, ...
  freqrange, durrange, amprange, figtitle, filelabel)

% function wlPlot_plotEventXYMulti(cfg, matchseries, ...
%   freqrange, durrange, amprange, figtitle, filelabel)
%
% This function makes a scatter-plot of detected parameter values vs
% ground-truth parameter values for frequency, duration, and amplitude.
%
% Plotted frequency and amplitude are the arithmetic means of the
% instantaneous frequency and amplitude curves in the event records.
% Error bars for these values are shown.
%
% "cfg" contains figure configuration information (see FIGCONFIG.txt").
% "matchseries" is an array of structures with the following fields:
%   "color" [r g b]:  The color to use for this series of records.
%   "legend":  The legend title to use for this series of records.
%   "matchlist":  A [1xN] array of structures with the following fields:
%     "truth":  Ground-truth event record (per wlSynth_traceAddBursts).
%     "test":   Detected event record (per wlSynth_traceAddBursts).
% "freqrange" [min max] defines the frequency range to be plotted (logscale).
% "durrange" [min max] defines the duration range to be plotted (linear).
% "amprange" [min max] defines the amplitude range to be plotted (logscale).
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within figure filenames to identify this figure.


%
% Build mean and standard deviation values for plotted parameters.

outcount = 0;

for sidx = 1:length(matchseries)

  thismatchlist = matchseries(sidx).matchlist;

  clear thisauxground thisauxdetect;

  for eidx = 1:length(thismatchlist)

    thisground = thismatchlist(eidx).truth;
    thisdetect = thismatchlist(eidx).test;


    % Average instantaneous parameter values.
    % If those don't exist, average the nominal ramp endpoints.


    s1 = thisground.s1;
    s2 = thisground.s2;

    if isfield(thisground, 'freq')
      freqseries = thisground.freq(s1:s2);
    else
      freqseries = [ thisground.f1 thisground.f2 ];
    end

    thisauxground.fmean(eidx) = mean(freqseries);
    thisauxground.fdev(eidx) = std(freqseries);

    if isfield(thisground, 'mag')
      magseries = thisground.mag(s1:s2);
    else
      magseries = [ thisground.a1 thisground.a2 ];
    end

    thisauxground.amean(eidx) = mean(magseries);
    thisauxground.adev(eidx) = std(magseries);

    thisauxground.dmean(eidx) = ...
      thisground.duration * thisauxground.fmean(eidx);
    thisauxground.ddev(eidx) = ...
      thisground.duration * thisauxground.fdev(eidx);


    s1 = thisdetect.s1;
    s2 = thisdetect.s2;

    if isfield(thisdetect, 'freq')
      freqseries = thisdetect.freq(s1:s2);
    else
      freqseries = [ thisdetect.f1 thisdetect.f2 ];
    end

    thisauxdetect.fmean(eidx) = mean(freqseries);
    thisauxdetect.fdev(eidx) = std(freqseries);

    if isfield(thisdetect, 'mag')
      magseries = thisdetect.mag(s1:s2);
    else
      magseries = [ thisdetect.a1 thisdetect.a2 ];
    end

    thisauxdetect.amean(eidx) = mean(magseries);
    thisauxdetect.adev(eidx) = std(magseries);

    thisauxdetect.dmean(eidx) = ...
      thisdetect.duration * thisauxdetect.fmean(eidx);
    thisauxdetect.ddev(eidx) = ...
      thisdetect.duration * thisauxdetect.fdev(eidx);

  end

  if 0 < length(thismatchlist)

    outcount = outcount + 1;

    oldidx(outcount) = sidx;
    auxground(outcount) = thisauxground;
    auxdetect(outcount) = thisauxdetect;

  end

end


%
%
% Plot the resulting data.


figure(cfg.fig);


%
% Frequency.

clf('reset');

hold on;

for sidx = 1:outcount

  thisrecord = matchseries(oldidx(sidx));
  thisauxground = auxground(sidx);
  thisauxdetect = auxdetect(sidx);

  % Remember that it's X, Y, _Yerr-_, _Yerr+_, Xerr-, Xerr+.

  errorbar( thisauxground.fmean, thisauxdetect.fmean, ...
    thisauxdetect.fdev, thisauxdetect.fdev, ...
    thisauxground.fdev, thisauxground.fdev, ...
    'o', 'Color', thisrecord.color, 'Displayname', thisrecord.legend );

end

% Diagonal.
plot(freqrange, freqrange, 'k-', 'HandleVisibility', 'off');

hold off;

xlabel('True Frequency (Hz)');
xlim(freqrange);
set(gca, 'Xscale', 'log');

ylabel('Detected Frequency (Hz)');
ylim(freqrange);
set(gca, 'Yscale', 'log');

legend('show', 'Location', 'northwest');

title( sprintf('%s - Extracted Frequency', figtitle) );
saveas(cfg.fig, sprintf('%s/evxymult-freq-%s.png', cfg.outdir, filelabel));


%
% Duration.

clf('reset');

hold on;

for sidx = 1:outcount

  thisrecord = matchseries(oldidx(sidx));
  thisauxground = auxground(sidx);
  thisauxdetect = auxdetect(sidx);

  % Remember that it's X, Y, _Yerr-_, _Yerr+_, Xerr-, Xerr+.

  errorbar( thisauxground.dmean, thisauxdetect.dmean, ...
    thisauxdetect.ddev, thisauxdetect.ddev, ...
    thisauxground.ddev, thisauxground.ddev, ...
    'o', 'Color', thisrecord.color, 'Displayname', thisrecord.legend );

end

% Diagonal.
plot(durrange, durrange, 'k-', 'HandleVisibility', 'off');

hold off;

xlabel('True Duration (cycles)');
xlim(durrange);
set(gca, 'Xscale', 'linear');

ylabel('Extracted Duration (cycles)');
ylim(durrange);
set(gca, 'Yscale', 'linear');

legend('show', 'Location', 'northwest');

title( sprintf('%s - Extracted Duration', figtitle) );
saveas(cfg.fig, sprintf('%s/evxymult-dur-%s.png', cfg.outdir, filelabel));


%
% Amplitude.

clf('reset');

hold on;

for sidx = 1:outcount

  thisrecord = matchseries(oldidx(sidx));
  thisauxground = auxground(sidx);
  thisauxdetect = auxdetect(sidx);

  % Remember that it's X, Y, _Yerr-_, _Yerr+_, Xerr-, Xerr+.

  errorbar( thisauxground.amean, thisauxdetect.amean, ...
    thisauxdetect.adev, thisauxdetect.adev, ...
    thisauxground.adev, thisauxground.adev, ...
    'o', 'Color', thisrecord.color, 'Displayname', thisrecord.legend );

end

% Diagonal.
plot(amprange, amprange, 'k-', 'HandleVisibility', 'off');

hold off;

xlabel('True Mean Amplitude (a.u.)');
xlim(amprange);
set(gca, 'Xscale', 'log');

ylabel('Detected Mean Amplitude (a.u.)');
ylim(amprange);
set(gca, 'Yscale', 'log');

legend('show', 'Location', 'northwest');

title( sprintf('%s - Extracted Amplitude', figtitle) );
saveas(cfg.fig, sprintf('%s/evxymult-amp-%s.png', cfg.outdir, filelabel));


%
% Done.

end

%
% This is the end of the file.
