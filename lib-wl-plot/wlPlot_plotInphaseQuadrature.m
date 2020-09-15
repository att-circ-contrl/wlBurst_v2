function wlPlot_plotInphaseQuadrature(cfg, times, wave_i, wave_q, ...
  figtitle, filelabel)

% function wlPlot_plotInphaseQuadrature(cfg, times, wave_i, wave_q, ...
%   figtitle, filelabel)
%
% This function plots two time-series waveforms, labeled as the in-phase and
% quadrature portions of a signal.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "times" is a [1xN] array of time values.
% "wave_i" is a [1xN] array of in-phase signal waveform values.
% "wave_q" is a [1xN] array of quadrature signal waveform values.
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within the figure filename to identify this figure.

figure(cfg.fig);
clf('reset');

plot(times, wave_i, times, wave_q);

title(figtitle);
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');
legend({'in-phase', 'quadrature'});

saveas(cfg.fig, sprintf('%s/time-iq-%s.png', cfg.outdir, filelabel));


%
% Done.

end

%
% This is the end of the file.
