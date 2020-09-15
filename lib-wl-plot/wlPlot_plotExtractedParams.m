function wlPlot_plotExtractedParams(cfg, times, wave, env, freq, phase, ...
  figtitle, filelabel)

% function wlPlot_plotExtractedParams(cfg, times, wave, env, freq, phase, ...
%   figtitle, filelabel)
%
% This function plots a time-series waveform, its envelope, its instantaneous
% frequency, and its instantaneous phase as three subfigures (envelope is
% superimposed on the waveform plot).
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "times" is a [1xN] array of time values.
% "wave" is a [1xN] array of signal waveform values.
% "env" is a [1xN] array of envelope waveform values.
% "freq" is a [1xN] array of instantaneous frequency values.
% "phase" is a [1xN] array of instantanous phase values, in radians. This is
%   converted to degrees when plotted.
% "figtitle" is the title to apply to the figure. Subfigures have a prefix
%   prepended to this title.
% "filelabel" is used within the figure filename to identify this figure.

figure(cfg.fig);
clf('reset');


subplot(3,1,1);

plot(times, wave, times, env);

title(sprintf('Envelope - %s', figtitle));
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');

% Don't draw a legend; identity is obvious, and it hides part of the curve.
%legend({'signal', 'envelope'});


subplot(3,1,2);

plot(times, freq);

title(sprintf('Frequency - %s', figtitle));
xlabel('Time (s)');
ylabel('Frequency (Hz)');


subplot(3,1,3);

plot(times, phase * (180 / pi));

title(sprintf('Phase - %s', figtitle));
xlabel('Time (s)');
ylabel('Phase (degrees)');


saveas(cfg.fig, sprintf('%s/ext-%s.png', cfg.outdir, filelabel));


%
% Done.

end


%
% This is the end of the file.
