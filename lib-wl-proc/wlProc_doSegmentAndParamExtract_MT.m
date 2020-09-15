function [ events auxwaves auxdata ] = wlProc_doSegmentAndParamExtract_MT( ...
  wavedata, samprate, bpfband, segconfig, paramconfig)

% function [ events auxwaves auxdata ] = ...
%   wlProc_doSegmentAndParamExtract_MT( ...
%     wavedata, samprate, bpfband, segconfig, paramconfig)
%
% This function performs event segmentation and parameter extraction on the
% specified waveform. Specific algorithms and their tuning parameters are
% selected/specified via configuration structures.
% This is a wrapper that forces multithreaded operation.
%
% "wavedata" is the data trace to examine.
% "samprate" is the number of samples per second in the signal data.
% "bpfband" [min max] is the frequency band of interest. Edges may fade.
% "segconfig" is a structure containing configuration information for
%   event segmentation, per SEGCONFIG.txt.
% "paramconfig" is a structure containing configuration information for
%   event parameter estimation, per PARAMCONFIG.txt.
% "wantmultithread" is "true" if _MT variants of functions are to be called.
%   This parameter is optional; the default is "false" (single-threaded).
%
% "events" is an array of structures describing detected events. Format is
%   per EVENTFORMAT.txt.
% "auxwaves" is a structure containing derived waveforms. These are
%   algorithm-specific, but typically include a band-pass-filtered version
%   of the original waveform and an analytic signal derived from this.
% "auxdata" is a structure containing other algorithm-specific metadata about
%   the analysis.


% Wrap the general version, forcing multithreaded operation.

[ events auxwaves auxdata ] = wlProc_doSegmentAndParamExtract( ...
  wavedata, samprate, bpfband, segconfig, paramconfig, true);


%
% Done.

end


%
% This is the end of the file.
