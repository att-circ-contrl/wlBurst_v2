function wlPlot_plotEventsAgainstCommon(cfg, evlist, evstride, ...
  signal, samprate, figtitle, filelabel)

% function wlPlot_plotEventsAgainstCommon(cfg, evlist, evstride, ...
%   signal, samprate, figtitle, filelabel)
%
% This function plots a series of events, showing the reconstructed signal's
% analytic components against the original signal's components.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "evlist" is a list of event records, in the form used by traceAddBursts().
% "evstride" suppresses plots; one out of every "evstride" events is plotted.
% "signal" is a structure containing the following fields:
%   "wave":   The signal amplitude values.
%   "mag":    The instantaneous magnitude of the signal.
%   "freq":   The instantaneous frequency of the signal.
%   "phase":  The instantaneous phase of the signal.
% "samprate" is the number of samples per second in signal and event data.
% "figtitle" is the title to apply to the figure. Subfigures have a prefix
%   prepended to this title.
% "filelabel" is used within the figure filename to identify this figure.


%
% Initialize.


colconsig = [ 0.0 0.4 0.7 ];
colconenv = [ 0.8 0.4 0.1 ];
colevsig = [ 0.9 0.7 0.1 ];
colevenv = [ 0.5 0.2 0.5 ];


alltimes = 1:length(signal.wave);
alltimes = alltimes / samprate;


%
% Render the figure.


figure(cfg.fig);
clf('reset');

subplot(3,1,1);

hold on;

plot( alltimes, signal.wave, 'Color', colconsig );
plot( alltimes, signal.mag, 'Color', colconenv );

for eidx = 1:evstride:length(evlist)
  thisev = evlist(eidx);
  tofs = thisev.sampstart / samprate;
  plot( thisev.times + tofs, thisev.wave, 'Color', colevsig );
  plot( thisev.times + tofs, thisev.mag, 'Color', colevenv );
end

hold off

set(gca, 'Box', 'on');

title(sprintf('Waveform - %s', figtitle));
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');


subplot(3,1,2);

hold on;

plot( alltimes, signal.freq, 'Color', colconsig );

for eidx = 1:evstride:length(evlist)
  thisev = evlist(eidx);
  tofs = thisev.sampstart / samprate;
  plot( thisev.times + tofs, thisev.freq, 'Color', colevsig );
end

hold off

set(gca, 'Box', 'on');

title(sprintf('Frequency - %s', figtitle));
xlabel('Time (s)');
ylabel('Frequency (Hz)');


subplot(3,1,3);

hold on;

plot( alltimes, signal.phase * (180 / pi), 'Color', colconsig );

for eidx = 1:evstride:length(evlist)
  thisev = evlist(eidx);
  tofs = thisev.sampstart / samprate;
  plot( thisev.times + tofs, thisev.phase * (180 / pi), 'Color', colevsig );
end

hold off

set(gca, 'Box', 'on');

title(sprintf('Phase - %s', figtitle));
xlabel('Time (s)');
ylabel('Phase (degrees)');


%
% Save the figure.


saveas(cfg.fig, sprintf('%s/common-%s.png', cfg.outdir, filelabel));


%
% Done.

end  % Function.

%
% This is the end of the file.
