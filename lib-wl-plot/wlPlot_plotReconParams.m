function wlPlot_plotReconParams(cfg, realtimes, realwave, ...
  exttimes, extmag, extphase, figtitle, filelabel)

% function wlPlot_plotReconParams(cfg, realtimes, realwave, ...
%   exttimes, extmag, extphase, figtitle, filelabel)
%
% This function plots a reconstructed time-series burst waveform against
% the real data from which it was extracted.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "realtimes" is a [1xN] array of time values from the real waveform.
% "realwave" is a [1xN] array of real signal waveform values.
% "exttimes" is a [1xN] array of time values for extracted magnitude/phase.
% "extmag" is a [1xN] array of extracted instantaneous magnitude values.
% "extphase" is a [1xN] array of extracted instantaneous phase angles (in rad).
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within the figure filename to identify this figure.

figure(cfg.fig);
clf('reset');

plot( realtimes, realwave, ...
  exttimes, extmag .* cos(extphase) );

title(figtitle);
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');

legend({'signal', 'reconstruction'});

saveas(cfg.fig, sprintf('%s/recon-%s.png', cfg.outdir, filelabel));


%
% Done.

end


%
% This is the end of the file.
