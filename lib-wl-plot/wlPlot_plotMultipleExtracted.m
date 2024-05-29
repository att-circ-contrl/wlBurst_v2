function wlPlot_plotMultipleExtracted(cfg, ...
  wavelist, freqlist, phaselist, ...
  figtitle, filelabel);

% function wlPlot_plotMultipleExtracted(cfg, ...
%   wavelist, freqlist, phaselist, ...
%   figtitle, filelabel);
%
% This function plots multiple time-series waveforms, multiple instantaneous
% frequency series, and multiple instantaneous phase series as three
% subfigures.
%
% No legends are specified; there usually isn't enough room with subfigures.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "wavelist" is an array of structures defining waveform traces.
% "freqlist" is an array of structures defining frequency plots.
% "phaselist" is an array of structures defining phase plots.
%   Phase is in radians; it's converted to degrees for plotting.
% "figtitle" is the title to apply to the figure. Subfigures have a prefix
%   prepended to this title.
% "filelabel" is used within the figure filename to identify this figure.
%
% Waveform definition structures contain three fields:
% "waveform.times" is a [1xN] array of time values.
% "waveform.data" is a [1xN] array of data samples.
% "waveform.color" is a [1x3] array of color component values (0..1 RGB).

figure(cfg.fig);
clf('reset');

subplot(3,1,1);

hold on;

for fidx = 1:length(wavelist)
  plot( wavelist(fidx).times, wavelist(fidx).data, ...
    'Color', wavelist(fidx).color );
end

hold off;

% Not sure why this changed.
set(gca, 'Box', 'on');

title(sprintf('Wave - %s', figtitle));
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');


subplot(3,1,2);

hold on;

for fidx = 1:length(freqlist)
  plot( freqlist(fidx).times, freqlist(fidx).data, ...
    'Color', freqlist(fidx).color );
end

hold off;

% Not sure why this changed.
set(gca, 'Box', 'on');

title(sprintf('Freq - %s', figtitle));
xlabel('Time (s)');
ylabel('Frequency (Hz)');


subplot(3,1,3);

hold on;

for fidx = 1:length(phaselist)
  plot( phaselist(fidx).times, phaselist(fidx).data * (180 / pi), ...
    'Color', phaselist(fidx).color );
end

hold off;

% Not sure why this changed.
set(gca, 'Box', 'on');

title(sprintf('Phase - %s', figtitle));
xlabel('Time (s)');
ylabel('Phase (degrees)');


saveas(cfg.fig, sprintf('%s/multi-%s.png', cfg.outdir, filelabel));


%
% Done.

end


%
% This is the end of the file.
