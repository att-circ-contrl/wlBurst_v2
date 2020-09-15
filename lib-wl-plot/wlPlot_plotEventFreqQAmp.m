function wlPlot_plotEventFreqQAmp(cfg, events, f1, f2, figtitle, filelabel)

% function wlPlot_plotEventFreqQAmp(cfg, events, f1, f2, figtitle, filelabel)
%
% This function makes a scatter-plot of frequency and duration (in periods)
% for detected bursts, and a scatter-plot of frequency and detected
% amplitudes.
%
% Plotted frequency is the arithmetic mean of instantaneous frequency.
% Error bars for frequency (and corresponding uncertainty in duration in
% periods) are shown. Plotted amplitude is the arithmetic mean of
% instantaneous envelope magnitude.
%
% "cfg" contains figure configuration information (see FIGCONFIG.txt").
% "events" is an array of event records (per wlSynth_traceAddBursts).
% "f1" and "f2" define the minimum and maximum frequencies to be plotted.
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within figure filenames to identify this figure.

%
%
% Walk through the event list, building data to plot.

for eidx = 1:length(events)

thisevent = events(eidx);

% Get fallback estimates by averaging the nominal start/end values.

ftmpmean = 0.5 * (thisevent.f1 + thisevent.f2);
ftmpdev = abs(thisevent.f1 - ftmpmean);
atmpmean = 0.5 * (thisevent.a1 + thisevent.a2);
atmpdev = abs(thisevent.a1 - atmpmean);

% Boost frequency uncertainty due to duration uncertainty.
% Assume this is not correlated with frequency tracking uncertainty.
funcert = 1.0 / thisevent.duration;
ftmpudev = sqrt(ftmpdev * ftmpdev + funcert * funcert);

favgmean(eidx) = ftmpmean;
favgdev(eidx) = ftmpdev;
favgudev(eidx) = ftmpudev;
aavgmean(eidx) = atmpmean;
aavgdev(eidx) = atmpdev;
davgmean(eidx) = thisevent.duration * ftmpmean;
davgdev(eidx) = thisevent.duration * ftmpdev;
davgudev(eidx) = thisevent.duration * ftmpudev;

% Get better estimates by averaging the instantaneous values.

if isfield(thisevent, 'freq') && isfield(thisevent, 'mag')

  s1 = thisevent.s1;
  s2 = thisevent.s2;

  ftmpmean = mean(thisevent.freq(s1:s2));
  ftmpdev = std(thisevent.freq(s1:s2));
  atmpmean = mean(thisevent.mag(s1:s2));
  atmpdev = std(thisevent.mag(s1:s2));

  % Boost frequency uncertainty due to duration uncertainty.
  % Assume this is not correlated with frequency tracking uncertainty.
  funcert = 1.0 / thisevent.duration;
  ftmpudev = sqrt(ftmpdev * ftmpdev + funcert * funcert);

  finstmean(eidx) = ftmpmean;
  finstdev(eidx) = ftmpdev;
  finstudev(eidx) = ftmpudev;
  ainstmean(eidx) = atmpmean;
  ainstdev(eidx) = atmpdev;
  dinstmean(eidx) = thisevent.duration * ftmpmean;
  dinstdev(eidx) = thisevent.duration * ftmpdev;
  dinstudev(eidx) = thisevent.duration * ftmpudev;

else

  % FIXME - Fall back silently if we don't have instantaneous waves.

  finstmean = favgmean;
  finstdev = favgdev;
  finstudev = favgudev;
  ainstmean = aavgmean;
  ainstdev = aavgdev;
  dinstmean = davgmean;
  dinstdev = davgdev;
  dinstudev = davgudev;

end

end

%
%
% Plot the resulting data.

% NOTE - Handle the zero-length list case gracefully.
if 0 < length(events)

% FIXME - Ignoring fallback/endpoint data. Just using mean instantaneous.

%
% Duration vs frequency.

figure(cfg.fig);
clf('reset');

errorbar(finstmean, dinstmean, ...
  dinstudev, dinstudev, finstudev, finstudev, ...
  'o', 'Color', [0 0.7 0.7]);
hold on
errorbar(finstmean, dinstmean, ...
  dinstdev, dinstdev, finstdev, finstdev, ...
  'o', 'Color', [0 0 1], 'LineWidth', 1.0);
hold off

xlabel('Frequency (Hz)');
%xlim([1 inf]);
xlim([ f1 f2 ]);
set(gca, 'Xscale', 'log');

ylabel('Duration (cycles)');
%ylim([0 inf]);
% FIXME - This is very sensitive to the events we're plotting.
ylim([ 0 7 ]);

title(figtitle);
saveas(cfg.fig, sprintf('%s/ev-dur-%s.png', cfg.outdir, filelabel));

%
% Amplitude vs frequency.

clf('reset');

errorbar(finstmean, ainstmean, ...
  ainstdev, ainstdev, finstudev, finstudev, ...
  'o', 'Color', [0 0.7 0.7]);
hold on
errorbar(finstmean, ainstmean, ...
  ainstdev, ainstdev, finstdev, finstdev, ...
  'o', 'Color', [0 0 1], 'LineWidth', 1.0);
hold off

xlabel('Frequency (Hz)');
%xlim([1 inf]);
xlim([ f1 f2 ]);
set(gca, 'Xscale', 'log');

ylabel('Mean Envelope Amplitude (a.u.)');
%ylim([1e-3 inf]);
ylim([ 1e-2 10 ]);
set(gca, 'Yscale', 'log');

title(figtitle);
saveas(cfg.fig, sprintf('%s/ev-amp-%s.png', cfg.outdir, filelabel));

end % Empty list check.

%
%
% Done.

end

%
% This is the end of the file.
