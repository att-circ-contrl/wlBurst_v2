function [ rawwave, hilmag, hilfreq, hilphase ] = ...
  wlProc_calcNoisyAnalytic(data, samprate, sigband, noiseband, noisesnr)

% function [ rawwave, hilmag, hilfreq, hilphase ] = ...
%   wlProc_calcNoisyAnalytic(data, samprate, sigband, noiseband, noisesnr)
%
% This function adds band-limited noise to a signal and then returns the
% analytic signal components of the noisy signal. Frequency is calculated
% using the first difference of phase (this function wraps
% wlProc_calcAnalytic).
%
% "data" is the real-valued signal to analyze.
% "samprate" is the number of samples per second in the signal data.
% "sigband" [min max] is the band to measure signal power in.
% "noiseband" [min max] is the band to add white noise in.
% "noisesnr" is the ratio of signal power to white noise power, in dB.
%
% "rawwave" contains the noisy waveform samples.
% "hilmag" contains analytic signal instantaneous magnitudes.
% "hilfreq" contains the estimated instantaneous frequency of the signal.
%   This can be anywhere from -nyquist to +nyquist for a noisy signal.
% "hilphase" contains analytic signal instantaneous phase angles. These are
%   in the range 0..2pi (i.e. not unwrapped).


% Add white noise with the desired SNR.

% Pad the detection bands when estimating power, to reduce edge effects.
% There's a limit to how much we can pad the noise band before hitting the
% Nyquist rate, though.

powersignal = bandpower(data, samprate, sigband);
powernoise = powersignal / (10^(noisesnr/20));
rawwave = wlSynth_traceAddNoise(data, samprate, 'white', ...
  noiseband(1), noiseband(2), powernoise, 0.8*noiseband(1), 1.2*noiseband(2));


% Calculate the analytic signal components.

[hilmag, hilfreq, hilphase] = wlProc_calcAnalytic(rawwave, samprate);


% Done.

end

%
% This is the end of the file.
