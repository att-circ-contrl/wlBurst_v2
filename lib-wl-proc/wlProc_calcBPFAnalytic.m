function [ rawwave, hilmag, hilfreq, hilphase ] = ...
  wlProc_calcBPFAnalytic(data, samprate, bpfband)

% function [ rawwave, hilmag, hilfreq, hilphase ] = ...
%   wlProc_calcBPFAnalytic(data, samprate, bpfband)
%
% This function band-pass filters an input signal, and then returns the
% analytic signal components of the band-limited signal. Frequency is
% calculated using the first difference of phase (this function wraps
% wlProc_calcAnalytic).
%
% "data" is the real-valued signal to analyze.
% "samprate" is the number of samples per second in the signal data.
% "bpfband" [min max] is the frequency band of interest. Edges may fade.
%
% "rawwave" contains the noisy band-limited waveform samples.
% "hilmag" contains analytic signal instantaneous magnitudes.
% "hilfreq" contains the estimated instantaneous frequency of the signal.
%   This can be anywhere from -nyquist to +nyquist for a noisy signal.
% "hilphase" contains analytic signal instantaneous phase angles. These are
%   in the range 0..2pi (i.e. not unwrapped).


% Band-pass filter the trace.
% Use zero-padding to reduce edge artifacts.

rawwave = wlProc_calcPaddedBandpass(data, bpfband, samprate);

% Calculate the analytic signal components.

[hilmag, hilfreq, hilphase] = wlProc_calcAnalytic(rawwave, samprate);


% Done.

end

%
% This is the end of the file.
