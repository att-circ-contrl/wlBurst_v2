function [ powerfast, powerslow ] = ...
  wlProc_calcMagPowerFastSlow(magsignal, samprate, flong, fshort)

% function [ powerfast, powerslow ] = ...
%   wlProc_calcMagPowerFastSlow(magsignal, samprate, flong, fshort)
%
% This function computes the instantaneous power of the fast-changing and
% slowly-changing portions of a supplied magnitude waveform (a real and
% non-negative signal).
%
% Each of these is computed as the squared value of a low-pass-filtered
% version of the input signal, using different filter corner frequencies.
% If "fshort" is omitted, the "fast-changing" signal is the input signal.
%
% "magsignal" is a real-valued non-negative signal to analyze.
% "samprate" is the number of samples per second in the signal data.
% "flong" is the maximum frequency in the "slowly-changing" signal. Set this
%   to zero to use the DC average.
% "fshort" is the maximum frequency in the "fast-changing" signal.
%
% "powerfast" is the instantaneous power of the fast-changing signal.
% "powerslow" is the instantaneous power of the slowly-changing signal.


% FIXME - Matlab's filter has problems with very low frequencies.
% Using my cosine window low-pass filter. Mushier cutoff but stable.

% Tuning parameter for wlProc_calcShortLowpass().
filtfactor = 2;


% Low-cutoff magnitude signal.

if 0 < flong
  magslow = wlProc_calcShortLowpass(magsignal, flong, samprate, filtfactor);
else
  magslow = ones(size(magsignal)) * mean(magsignal);
end


% High-cutoff magnitude signal.

if exist('fshort', 'var')

% Use the specified high-frequency cutoff.

magfast = wlProc_calcShortLowpass(magsignal, fshort, samprate, filtfactor);

else

% No high-frequency cutoff. Use the input signal.

magfast = magsignal;

end


% Instantaneous power.

powerslow = magslow .* magslow;
powerfast = magfast .* magfast;


% Done.

end

%
% This is the end of the file.
