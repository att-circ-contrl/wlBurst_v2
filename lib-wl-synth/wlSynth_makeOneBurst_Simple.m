function [errcode, times, wave, mag, freq, phase] = ...
  wlSynth_makeOneBurst_Simple(samprate, f1, f2, a1, a2, pstart, periods)

% function [errcode, times, wave, mag, freq, phase] = ...
%   wlSynth_makeOneBurst_Simple(samprate, f1, f2, a1, a2, pstart, periods)
%
% This function generates an oscillatory burst aligned to t=0.
% This is a wrapper for wlSynth_makeOneBurst with simplified arguments.
%
% "samprate" is the number of samples per second in the generated data.
% "f1" and "f2" are the frequencies at the start and end of the burst.
% "a1" and "a2" are the amplitudes at the start and end of the burst.
% "pstart" is the phase at the start of the burst.
% "periods" is the time between midpoints of the envelope's rising/falling
%   edges, in cycles at the average frequency ( (f1 + f2) / 2 ).
%
% The burst uses a Tukey window (with cosine roll-off). The midpoint of the
% rising edge of the window is at t=0; the distance between midpoints of
% the rising and falling edges is the duration. Rise time and fall time are
% one (average) period.
%
% "errcode" is "ok" on success or a descriptive error message on failure.
% "times" is a [1xN] array of sample timestamps.
% "wave" is a [1xN] array containing the oscillatory burst waveform.
% "mag" is a [1xN] array containing the ground-truth envelope magnitude.
% "freq" is a [1xN] array containing the ground-truth instantaneous frequency.
% "phase" is a [1xN] array containing the ground-truth instantaneous phase in radians.

errcode = 'ok';

%
% Sanity check new arguments and arguments we derive values from.
% Everything else can be checked by wlSynth_makeOneBurst.

if (periods < 1)
  errcode = 'Duration must be at least 1 period.';
elseif ((f1 <= 0) || (f1 <= 0))
  errcode = 'Frequency must be positive.';
end

%
% If we had an error, show a message.
% Otherwise wrap wlSynth_makeOneBurst.

if ~(strcmp(errcode,'ok'))
  disp(errcode)
else
  fmid = 0.5 * (f1 + f2);
  permid = 1 / fmid;
  [errcode, times, wave, mag, freq, phase] = ...
    wlSynth_makeOneBurst(periods * permid, permid, permid, samprate, ...
      f1, f2, 'logarithmic', a1, a2, 'logarithmic', pstart);
end


%
% Done.

end

%
% This is the end of the file.
