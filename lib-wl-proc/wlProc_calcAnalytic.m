function [ rawmag, rawfreq, rawphase ] = ...
  wlProc_calcAnalytic(data, samprate)

% function [ rawmag, rawfreq, rawphase ] = ...
%   wlProc_calcAnalytic(data, samprate)
%
% This function uses the Hilbert transform to generate an analytic signal
% for the specified input signal, and from that extracts magnitude and phase.
% Frequency is calculated using the first difference of phase.
%
% Calculated frequency will be very noisy. The last sample of frequency is
% replicated, for consistent array lengths. The first sample of frequency
% occurs between the first and second samples of the other traces.
%
% "data" is the real-valued signal to analyze.
% "samprate" is the number of samples per second (used to calculate frequency).
%
% "rawmag" contains analytic signal instantaneous magnitudes.
% "rawfreq" contains the estimated instantaneous frequency of the signal.
% This can be anywhere from -nyquist to +nyquist; non-artifact values should
% be strictly positive and in biologically relevant bands.
% "rawphase" contains analytic signal instantaneous phase angles. These are
% in the range 0..2pi (i.e. not unwrapped).

% Get magnitude and phase the bog-standard way.

hdata = hilbert(data);
rawmag = abs(hdata);
rawphase = angle(hdata);

% Default unwrap clamps jumps to +/- pi radians.
unphase = unwrap(rawphase);
rawfreq = diff(unphase);
rawfreq = rawfreq * samprate / (2 * pi);
rawfreq(length(data)) = rawfreq(length(data) - 1);


%
% Done.

end

%
% This is the end of the file.
