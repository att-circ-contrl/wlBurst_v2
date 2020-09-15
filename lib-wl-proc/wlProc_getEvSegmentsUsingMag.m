function [ events, waves ] = wlProc_getEvSegmentsUsingMag( ...
  data, samprate, bpfband, maxglitch, maxdrop, taudc, threshdb)

% function [ events, waves ] = wlProc_getEvSegmentsUsingMag( ...
%   data, samprate, bpfband, maxglitch, maxdrop, taudc, threshdb)
%
% This function identifies the locations of oscillatory bursts in a data
% stream, returning a list of skeletal putative burst event records.
% The "UsingMag" implementation band-pass-filters the input signal, computes
% the analytic signal, and looks for excursions in analytic magnitude.
%
% "data" is the data trace to examine.
% "samprate" is the number of samples per second in the signal data.
% "bpfband" [min max] is the frequency band of interest. Edges may fade.
% "maxglitch" is the longest duration event to reject as spurious.
% "maxdrop" is the longest duration gap in an event to reject as spurious.
% "taudc" is the time constant for smoothing the "average" magnitude. Set this
%   to infinity to use the DC average.
% "threshdb" is the factor by which instantaneous power must exceed average
%   power for an event candidate to be generated.
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
%   "magpowerfast" is the rapidly-changing instantaneous power.
%   "magpowerslow" is the slowly-changing instantaneous power.


% Compute the band-limited analytic signal.
[ trace_bpf, hilmag, hilfreq, hilphase ] = ...
  wlProc_calcBPFAnalytic(data, samprate, bpfband);


% Filter the analytic magnitude, and get a running estimate of instantaneous
% power over short and long timescales.

flow = 1 / (2 * pi * taudc);

[ magpowerfast, magpowerslow ] = ...
  wlProc_calcMagPowerFastSlow(hilmag, samprate, flow);


% FIXME - Debugging.
if false

%disp(sprintf('(Mag) Using low-pass cutoff %.3f Hz (tau %.1s).', flow, taudc));

fname = sprintf('output/debug-mag-%.4fhz.png', flow);

times = 1:length(hilmag);
times = times / samprate;
%plotrange = 10000:11000;
plotrange = 10000:15000;
if false
% Full waveform.
plot(times, magpowerfast, times, magpowerslow);
else
% Zoomed in.
plot(times(plotrange), magpowerfast(plotrange), ...
  times(plotrange), magpowerslow(plotrange));
end
title(sprintf('Instantaneous Magnitude - Fdc: %.4f Hz', flow));
xlabel('Time (s)');
ylabel('Power (a.u.)');
legend({'instantaneous','average'});
%set(gca, 'Yscale', 'log');
saveas(gcf, fname);

end


% Figure out which portions are above-threshold.
% We're comparing power, not amplitude, so it's 10 dB per decade.

threshold = 10^(threshdb/10);

events = wlProc_getEvSegmentsByComparing(magpowerfast, magpowerslow, ...
  samprate, threshold, maxglitch, maxdrop);


% Store diagnostic waveforms.

waves = struct( 'bpfwave', trace_bpf, ...
  'bpfmag', hilmag, 'bpffreq', hilfreq, 'bpfphase', hilphase, ...
  'magpowerfast', magpowerfast, 'magpowerslow', magpowerslow );


% Done.

end

%
% This is the end of the file.
