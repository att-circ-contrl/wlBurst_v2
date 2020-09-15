function wlPlot_plotWaveAndSpec(cfg, times, wave, figtitle, filelabel)

% function wlPlot_plotWaveAndSpec(cfg, times, wave, figtitle, filelabel)
%
% This function plots a time-series waveform and a corresponding spectrogram.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "times" is a [1xN] array of time values.
% "wave" is a [1xN] array of signal waveform values.
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within figure filenames to identify this figure set.

figure(cfg.fig);
clf('reset');

plot(times, wave);

title(figtitle);
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');

saveas(cfg.fig, sprintf('%s/time-%s.png', cfg.outdir, filelabel));

clf('reset');

pspectrum(wave, cfg.fsamp, 'spectrogram', ...
  'FrequencyResolution', cfg.psfres, 'OverlapPercent', cfg.psolap, ...
  'Leakage', cfg.psleak, 'MinThreshold', -60);
ylim([0 cfg.psylim]);

title(figtitle);

saveas(cfg.fig, sprintf('%s/spect-%s.png', cfg.outdir, filelabel));


%
% Done.

end

%
% This is the end of the file.
