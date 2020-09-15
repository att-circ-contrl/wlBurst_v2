function [ events, waves ] = wlProc_getEvSegmentsUsingFreq(data, samprate, ...
  bpfband, noiseband, noisesnr, maxglitch, maxdrop, taudc, tauac, threshdb)

% function events = wlProc_getEvSegmentsUsingFreq(data, samprate, ...
%   bpfband, noiseband, noisesnr, maxglitch, maxdrop, taudc, tauac, threshdb)
%
% This function identifies the locations of oscillatory bursts in a data
% stream, returning a list of skeletal putative burst event records.
% The "UsingFreq" implementation band-pass-filters the input signal, computes
% the analytic signal, and looks for regions with stable instantaneous
% frequency. High-frequency white noise is added to reduce false positives.
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
% "threshdb" is the factor by which short-term frequency variance must be
%   suppressed with respect to average frequency variance for an event
%   candidate to be generated.
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


% FIXME - Debugging.
if false

%disp(sprintf('LPF cutoff: %.3f Hz (tau %.2f s)', freqshort, tauac));

fname = sprintf('output/debug-freq-%.4fhz-%.3fhz.png', freqlong, freqshort);

times = 1:length(hilfvar);
times = times / samprate;
% 1 second
%plotrange = 10000:11000;
% 5 seconds
plotrange = 10000:15000;
if false
plot(times, hilfvar, times, hilfvarshort, times, hilfvarlong);
else
% Zoomed in.
plot(times(plotrange), hilfvar(plotrange), ...
  times(plotrange), hilfvarshort(plotrange), ...
  times(plotrange), hilfvarlong(plotrange));
end
title(sprintf('Instantanoues Frequency - Fdc: %.4f Hz  Fpass: %.3f Hz', ...
  freqlong, freqshort));
xlabel('Time (s)');
ylabel('Variance (a.u.)');
legend({'unfiltered', 'fast-changing','average'});
%set(gca, 'Yscale', 'log');
saveas(gcf, fname);

end


% Figure out which portions are below-threshold.
% We're comparing variance, not amplitude, so it's 10 dB per decade.

threshold = 10^(threshdb/10);

events = wlProc_getEvSegmentsByComparing(hilfvarlong, hilfvarshort, ...
  samprate, threshold, maxglitch, maxdrop);


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
