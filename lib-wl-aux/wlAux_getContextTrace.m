function [ wavecontext, timescontext ] = ...
  wlAux_getContextTrace(wave, samprate, ...
    minlengths, mincycles, ...
    evfreq, evlength, evsampstart)

% function [ wavecontext, timescontext ] = ...
%   wlAux_getContextTrace(wave, samprate, ...
%     minlengths, mincycles, ...
%     evfreq, evlength, evsampstart)
%
% This function extracts a section of the input waveform containing "context"
% for an event. Timestamps are generated aligned with the event start time.
%
% "wave" is a [1xN] vector containing signal waveform data.
% "samprate" is the number of samples per second.
% "minlengths" is the minimum size of the surrounding context time as a
%   fraction of event duration.
% "mincycles" is the minimum size of the surrounding context time as a
%   fraction of the nominal cycle period of the event signal.
% "evfreq" is the nominal frequency of the event signal.
% "evlength" is the duration of the event in seconds.
% "evsampstart" is the sample index in "wave" corresponding to the nominal
%   starting time of the event.
%
% "wavecontext" is a [1xM] vector containing context waveform data.
% "timescontext" is a [1xM] vector containing context timestamp data.


% Get the context window padding length.

% Figure out the window duration based on cycle period.
contexttime = mincycles / max(1, evfreq);

% Use the duration-based window if that's longer.
contexttime = max(contexttime, minlengths * evlength);


% Get the relevant subset of the real data. Truncate it if necessary.

sampstart = evsampstart - round(contexttime * samprate);
sampstart = max(1, sampstart);

sampend = evsampstart + round( (evlength + contexttime) * samprate);
sampend = min(sampend, length(wave));


% Extract the relevant segment of the input wave.

wavecontext = wave(sampstart:sampend);

timescontext = [ sampstart : sampend ];
timescontext = (timescontext - evsampstart) / samprate;


% Done.

end


%
% This is the end of the file.
