function wlPlot_plotEventsWithContext(cfg, evlist, evstride, ...
  signal, samprate, fnom, contextlengths, contextcycles, ...
  figtitle, filelabel)

% function wlPlot_plotEventsWithContext(cfg, evlist, evstride, ...
%   signal, samprate, fnom, contextlengths, contextcycles, ...
%   figtitle, filelabel)
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
% "fnom" is the nominal frequency for purposes of context window size.
% "contextlengths" is the minimum size of the surrounding context as a
%   fraction of event duration.
% "contextcycles" is the minimum size of the surrounding context as a
%   fraction of the nominal cycle period of the event signal.
% "figtitle" is the title to apply to the figure. Subfigures have a prefix
%   prepended to this title. The event number is appended.
% "filelabel" is used within the figure filename to identify this figure.

cosig = [ 0.0 0.4 0.7 ];
coenv = [ 0.8 0.4 0.1 ];
cdsig = [ 0.9 0.7 0.1 ];
cdenv = [ 0.5 0.2 0.5 ];


for eidx = 1:evstride:length(evlist)

  thisev = evlist(eidx);


  % Get context.

  [conwave, contimes] = wlAux_getContextTrace(signal.wave, samprate, ...
    contextlengths, contextcycles, fnom, thisev.duration, thisev.sampstart);
  [conmag, contimes] = wlAux_getContextTrace(signal.mag, samprate, ...
    contextlengths, contextcycles, fnom, thisev.duration, thisev.sampstart);
  [confreq, contimes] = wlAux_getContextTrace(signal.freq, samprate, ...
    contextlengths, contextcycles, fnom, thisev.duration, thisev.sampstart);
  [conphase, contimes] = wlAux_getContextTrace(signal.phase, samprate, ...
    contextlengths, contextcycles, fnom, thisev.duration, thisev.sampstart);


  % Build this figure.

  wlPlot_plotMultipleExtracted( cfg, ...
    [ struct( 'times', contimes, 'data', conwave, 'color', cosig ) ...
      struct( 'times', contimes, 'data', conmag, 'color', coenv ) ...
      struct( 'times', thisev.times, 'data', thisev.wave, 'color', cdsig ) ...
      struct( 'times', thisev.times, 'data', thisev.mag, 'color', cdenv ) ...
    ], ...
    [ struct( 'times', contimes, 'data', confreq, 'color', cosig ) ...
      struct( 'times', thisev.times, 'data', thisev.freq, 'color', cdsig ) ...
    ], ...
    [ struct( 'times', contimes, 'data', conphase, 'color', cosig ) ...
      struct( 'times', thisev.times, 'data', thisev.phase, 'color', cdsig) ...
    ], ...
    sprintf('%s - Ev %04d', figtitle, eidx), ...
    sprintf('%s-%04d', filelabel, eidx) );


end  % Event iteration.


%
% Done.

end  % Function.

%
% This is the end of the file.
