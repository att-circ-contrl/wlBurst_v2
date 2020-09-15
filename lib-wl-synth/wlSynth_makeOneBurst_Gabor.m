function [errcode, times, wave, mag, freq, phase] = ...
  wlSynth_makeOneBurst_Gabor(samprate, f1, a1, pmid, periods)

% function [errcode, times, wave, mag, freq, phase] = ...
%   wlSynth_makeOneBurst_Gabor(samprate, f1, a1, pmid, periods)
%
% This function generates approximations of Gabor wavelets using
% wlSynth_makeOneBurst. These are cosine waves modulated by a von Hann
% window (raised cosine window).
% The center of the wavelet is aligned to t=0 (differing from the convention
% used by wlSynth_makeOneBurst).
%
% "samprate" is the number of samples per second in the generated data.
% "f1" is the nominal frequency of the wavelet.
% "a1" is the maximum amplitude of the modulation envelope.
% "pmid" is the cosine wave's phase at the midpoint of the wavelet.
%   A value of 0 gives a cosine wavelet; -pi/2 gives a sine wavelet.
% "periods" is the duration of the wavelet, in cycles. This is the full
%   width of the von Hann window, not the FHWM.
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
elseif (f1 <= 0)
  errcode = 'Frequency must be positive.';
end

%
% If we had an error, show a message.
% Otherwise wrap wlSynth_makeOneBurst.

if ~(strcmp(errcode,'ok'))
  disp(errcode)
else
  perwave = 1 / f1;
  fullduration = periods * perwave;
  halfduration = 0.5 * fullduration;

  % Phase at the rising threshold is midpoint phase backed off by 1/4 of the
  % duration (-pi/2 * periods).
  [errcode, times, wave, mag, freq, phase] = ...
    wlSynth_makeOneBurst(halfduration, halfduration, halfduration, ...
      samprate, f1, f1, 'linear', a1, a1, 'linear', ...
      pmid - 0.5 * pi * periods);

  % Time with Gabor conventions is the rising threshold time shifted by
  % 1/4 of the duration.
  times = times - (0.25 * fullduration);
end


%
% Done.

end

%
% This is the end of the file.
