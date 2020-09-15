function [errcode, times, wave, mag, freq, phase] = ...
  wlSynth_makeOneBurst(duration, rollon, rolloff, samprate, ...
    f1, f2, ftype, a1, a2, atype, pstart)

% function [errcode, times, wave, mag, freq, phase] = ...
%  wlSynth_makeOneBurst(duration, rollon, rolloff, samprate, ...
%    f1, f2, ftype, a1, a2, atype, pstart)
%
% This function generates an oscillatory burst aligned to t=0.
%
% "duration" is the time between the midpoints of the roll-on and roll-off
% (the FWHM of the roll-off window; this is not the FHWM of the burst itself).
% "rollon" is the roll-on time of the cosine roll-off window.
% "rolloff" is the roll-off time of the cosine roll-off window.
% "samprate" is the number of samples per second in the generated data.
% "f1" and "f2" are the frequencies at time 0 and time "duration".
% "a1" and "a2" are the amplitudes at time 0 and time "duration" BEFORE the
% application of the cosine roll-off window.
% "ftype" and "atype" are "linear" or "logarithmic", defining how frequency
% and amplitude vary. These use the same equations as "chirp".
% "pstart" is the phase at time zero, in radians.
%
% "errcode" is "ok" on success or a descriptive error message on failure.
% "times" is a [1xN] array of sample timestamps.
% "wave" is a [1xN] array containing the oscillatory burst waveform.
% "mag" is a [1xN] array containing the ground-truth envelope magnitude.
% "freq" is a [1xN] array containing the ground-truth instantaneous frequency.
% "phase" is a [1xN] array containing the ground-truth instantaneous phase in radians.

errcode = 'ok';


%
% Sanity check arguments.

if (duration <= 0)
  errcode = 'Need a positive duration.';
elseif (samprate <= 0)
  errcode = 'Need a positive sampling rate.';
elseif ( (0.5 * (rollon + rolloff)) > duration )
  errcode = 'Roll-on/roll-off time must fit in duration.';
elseif (f1 <= 0) || (f1 <= 0) || (a1 <= 0) || (a2 <= 0)
  errcode = 'Amplitude and frequency must be positive.';
  errcode = sprintf('%s (f: %.2f..%.2f  a: %.4f..%.4f)', errcode,f1,f2,a1,a2);
elseif ~( strcmpi(ftype,'linear') || strcmpi(ftype, 'logarithmic') )
  errcode = 'Bad frequency ramp type specified.';
elseif ~( strcmpi(atype,'linear') || strcmpi(atype, 'logarithmic') )
  errcode = 'Bad amplitude ramp type specified.';
else


  %
  % Calculate derived values.

  samp_dt = 1.0 / samprate;

  samprollon = round(rollon * samprate);
  samprolloff = round(rolloff * samprate);

  % Force these to be even, and record the half-duration.

  samprollonhalf = round(0.5 * samprollon);
  samprollon = samprollonhalf + samprollonhalf;

  samprolloffhalf = round(0.5 * samprolloff);
  samprolloff = samprolloffhalf + samprolloffhalf;

  sampfwhm = round(duration * samprate);
  % Force sanity for rare rounding cases.
  if sampfwhm < (samprollonhalf + samprolloffhalf)
    sampfwhm = samprollonhalf + samprolloffhalf;
  end

  samptotal = samprollonhalf + sampfwhm + samprolloffhalf;


  %
  % Build waveforms and related vectors.

  % Time values.

  % Go from 0 to samptotal rather than 1 to samptotal.
  % We'll adjust samptotal afterwards.
  times = 0:samptotal;
  times = times - samprollonhalf;
  times = times * samp_dt;

  % Avoid fencepost errors.
  samptotal = length(times);


  % Cosine roll-off window.
  % If roll-on and roll-off are equal, this is a Tukey window.

  window_raw = wlProc_calcCosineWindow( ...
    1 + samprollon, samptotal - samprolloff, samptotal );

% FIXME - Diagnostics.
if length(times) ~= length(window_raw)
disp(sprintf('** Length mismatch. times: %d   window: %d   samptotal: %d', ...
length(times), length(window_raw), samptotal));
disp(sprintf('  rollon: %d   rolloff: %d', samprollon, samprolloff));
end

  % Amplitude ramp.

  % Starting and ending values are positive, and we have at least one
  % sample and positive duration, so no special cases are needed.

  beta = (a2 - a1) / duration;
  amp_raw = times .* beta + a1;

  if strcmpi(atype,'logarithmic')
    beta = (a2 / a1)^(1 / duration);
    amp_raw = a1 * beta.^times;
  end


  % Angular frequency ramp and phase ramp.
  % Phase is the integral of frequency, plus starting phase.

  % Starting and ending values are positive, and we have at least one
  % sample and positive duration, so the only special case is f1 = f2 for
  % the log phase calculation.

  w1 = 2 * pi * f1;
  w2 = 2 * pi * f2;

  beta = (w2 - w1) / duration;
  freq_raw = times .* beta + w1;
  phase_raw = times * w1 + times .* times * (0.5 * beta);

  % If f1 is approximately equal to f2, keep the linear result.
  if strcmpi(ftype,'logarithmic') && ...
    ( (f1 > 1.0001 * f2) || (f1 < 0.9999 * f2) )
    beta = (w2 / w1)^(1 / duration);
    freq_raw = w1 * beta.^times;
    phase_raw = (freq_raw - w1) / log(beta);
  end

  % Save ground truth frequency and phase.
  freq = freq_raw ./ (2 * pi);
  phase = phase_raw + pstart;

  % Wrap the phase to -pi..pi.
  phase = mod(phase + pi, 2*pi) - pi;


  % Chirped cosine.
  % Calculate it directly from phase, rather than using chirp().

  chirp_raw = cos(phase);


  % Put it all together.

  mag = window_raw .* amp_raw;
  wave = chirp_raw .* mag;

  % Finished.

end


%
% If we had an error, show a message.

if ~(strcmp(errcode,'ok'))
  disp(errcode)

  % FIXME - Diagnostics.
  if true
    disp('-- Arguments:');
    disp(sprintf('Duration:  %.4f', duration));
    disp(sprintf('Roll on/off:  %.4f / %.4f', rollon, rolloff));
    disp(sprintf('Sampling rate:  %d', samprate));
    disp(sprintf('f1/f2:  %.3f / %.3f  (%s)', f1, f2, ftype));
    disp(sprintf('a1/a2:  %.4f / %.4f  (%s)', a1, a2, atype));
    disp(sprintf('Starting phase:  %.3f rad', pstart));
    disp('-- End of arguments.');
  end
end


%
% Done.

end


%
% This is the end of the file.
