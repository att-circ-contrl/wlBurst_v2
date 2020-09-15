function wlPlot_plotPowerAndPersist(cfg, wave, fmin, fmax, ...
  figtitle, filelabel)

% function wlPlot_plotPowerAndPersist(cfg, wave, fmin, fmax, ...
%   figtitle, filelabel)
%
% This function plots power spectral density and a persistence spectrum
% for the specified waveform.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "wave" is a [1xN] array of signal waveform values.
% "fmin" and "fmax" define the frequency range to be plotted.
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within figure filenames to identify this figure set.

figure(cfg.fig);
clf('reset');

pspectrum(wave, cfg.fsamp, 'power', ...
  'Leakage', cfg.psleak, 'MinThreshold', -60, ...
  'FrequencyLimits', [ fmin fmax ]);

title(figtitle);
% FIXME - Leave it as linear for now.
%set(gca, 'Xscale', 'log');

saveas(cfg.fig, sprintf('%s/power-%s.png', cfg.outdir, filelabel));

clf('reset');

pspectrum(wave, cfg.fsamp, 'persistence', ...
  'Leakage', cfg.psleak, ...
  'FrequencyLimits', [ fmin fmax ], ...
  'TimeResolution', 1);

title(figtitle);
% FIXME - Can't set this log. The heatmap cell matrix was computed with
% linear bins, so changing the axis to log just mislabels the linear plot.

saveas(cfg.fig, sprintf('%s/persist-%s.png', cfg.outdir, filelabel));


%
% Done.

end

%
% This is the end of the file.
