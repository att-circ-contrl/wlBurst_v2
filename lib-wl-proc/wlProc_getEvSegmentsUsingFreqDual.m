function [ events, waves ] = wlProc_getEvSegmentsUsingFreqDual( ...
  data, samprate, bpfband, noiseband, noisesnr, ...
  maxglitch, maxdrop, taudc, tauac, peakdb, enddb)

% function [ events, waves ] = wlProc_getEvSegmentsUsingFreqDual( ...
%   data, samprate, bpfband, noiseband, noisesnr, ...
%   maxglitch, maxdrop, taudc, tauac, peakdb, enddb)
%
% This function identifies the locations of oscillatory bursts in a data
% stream, returning a list of skeletal putative burst event records.
% The "UsingFreqDual" implementation band-pass-filters the input signal,
% computes the analytic signal, and looks for regions with stable
% instantaneous frequency. High-frequency white noise is added to reduce
% false positives.
% Frequency variance must be reduced by "peakdb" to be considered "stable",
% but endpoints only have to be reduced by "enddb".
%
% "data" is the data trace to examine.
% "samprate" is the number of samples per second in the signal data.
% "bpfband" [min max] is the frequency band of interest. Edges may fade.
% "noiseband" [min max] is the band to add white noise in.
% "noisesnr" is the ratio of signal power to white noise power, in dB.
% "maxglitch" is the longest duration event to reject as spurious.
% "maxdrop" is the longest duration gap in an event to reject as spurious.
% "taudc" is the time constant for smoothing "average" frequency variance.
%   Set this to infinity to use the DC average.
% "tauac" is the time constant for smoothing short-term frequency variance.
% "peakdb" is the factor by which short-term frequency variance must be
%   suppressed with respect to average frequency variance for an event
%   candidate to be generated.
% "enddb" is the factor by which short-term frequency variance must be
%   suppressed with respect to average frequency variance at event endpoints.
%
% "events" is an array of event record structures following the conventions
%   of wlSynth_traceAddBursts(). Only the following fields are provided:
%
%   "sampstart":  Sample index in "data" corresponding to burst nominal start.
%   "duration":   Time between burst nominal start and burst nominal stop.
%
% "waves" is a structure containing waveforms derived from "data":
%   "bpfwave" is the band-pass-filtered waveform.
%   "bpfmag" is the analytic magnitude of the bpf waveform.
%   "bpffreq" is the analytic frequency of the bpf waveform.
%   "bpfphase" is the analytic phase of the bpf waveform.
%   "noisywave" is the noisy version of the bpf waveform.
%   "noisymag" is the analytic magnitude of the noisy waveform.
%   "noisyfreq" is the analytic frequency of the noisy waveform.
%   "noisyphase" is the analytic phase of the noisy waveform.
%   "fvarfast" is the rapidly-changing variance of the instantaneous frequency.
%   "fvarslow" is the slowly-changing variance of the instantaneous frequency.

% Compute the band-limited analytic signal with noise added.

[ trace_bpf, bpfmag, bpffreq, bpfphase ] = ...
  wlProc_calcBPFAnalytic(data, samprate, bpfband);

[ trace_noisy, hilmag, hilfreq, hilphase ] = ...
  wlProc_calcNoisyAnalytic(trace_bpf, samprate, ...
    [ 0.5*bpfband(1), 2.0*bpfband(2) ], noiseband, noisesnr);


% Get a running estimate of the variance of the analytic frequency over short
% and long timescales.

freqlong = 1 / (2 * pi * taudc);
freqshort = 1 / (2 * pi * tauac);

[ hilfvarshort, hilfvarlong ] = ...
  wlProc_calcVarFastSlow(hilfreq, samprate, freqlong, freqlong, freqshort);


% Figure out which portions are below-threshold.
% We're comparing variance, not amplitude, so it's 10 dB per decade.

threshpeak = 10^(peakdb/10);
threshend = 10^(enddb/10);

events = wlProc_getEvSegmentsByComparingDual(hilfvarlong, hilfvarshort, ...
  samprate, threshpeak, threshend, maxglitch, maxdrop);


% Store diagnostic waveforms.

waves = struct( 'bpfwave', trace_bpf, ...
  'bpfmag', bpfmag, 'bpffreq', bpffreq, 'bpfphase', bpfphase, ...
  'noisywave', trace_noisy, ...
  'noisymag', hilmag, 'noisyfreq', hilfreq, 'noisyphase', hilphase, ...
  'fvarfast', hilfvarshort, 'fvarslow', hilfvarlong );


% Done.

end

%
% This is the end of the file.
