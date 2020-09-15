function [ varfast, varslow ] = ...
  wlProc_calcVarFastSlow(data, samprate, fdc, flong, fshort)

% function [ varfast, varslow ] = ...
%   wlProc_calcVarFastSlow(data, samprate, fdc, flong, fshort)
%
% This function calculates the fast-changing and slowly-changing portions
% of the variance of a supplied signal waveform.
%
% The local mean of the signal is obtained by low-pass-filtering with
% cuttoff "fdc". The instantaneous variance is computed by squaring the
% residue after the local mean is subtracted. Rapidly-changing and slowly-
% -changing variances are computed by low-pass-filtering the instantaneous
% variance with cutoffs "fshort" and "flong", respectively; these calculate
% the average of the instantaneous windows within their equivalent windows.
%
% "data" is a real-valued signal to analyze.
% "samprate" is the number of samples per second in the signal data.
% "fdc" is the maximum frequency in the "mean" signal. Set this to zero to
%   use the DC average.
% "flong" is the maximum frequency in the "slowly-changing" variance signal.
%   Set this to zero to use the DC average.
% "fshort" is the maximum frequency in the "fast-changing" variance signal.
%
% "varfast" is the "fast-changing" running variance signal.
% "varslow" is the "slowly-changing" running variance signal.


% FIXME - Matlab's filter has problems with very low frequencies.
% Using my cosine window low-pass filter. Mushier cutof but stable.

% Tuning parameter for wlProc_calcShortLowpass().
filtfactor = 2;


% Calculate mean signal and instantaneous variance.

if 0 < fdc
  avgdata = wlProc_calcShortLowpass(data, fdc, samprate, filtfactor);
else
  avgdata = ones(size(data)) * mean(data);
end

rawvar = data - avgdata;
rawvar = rawvar .* rawvar;


% Calculate average variance over short and long timescales.

varfast = wlProc_calcShortLowpass(rawvar, fshort, samprate, filtfactor);

if 0 < flong
  varslow = wlProc_calcShortLowpass(rawvar, flong, samprate, filtfactor);
else
  varslow = ones(size(rawvar)) * mean(rawvar);
end


% Done.

end

%
% This is the end of the file.
