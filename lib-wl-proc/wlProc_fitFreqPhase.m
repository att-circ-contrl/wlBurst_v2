function [ newevent, error ] = wlProc_fitFreqPhase( ...
  hilfreq, hilphase, oldevent)

% function [ newevent, error ] = wlProc_fitFreqPhase( ...
%   hilfreq, hilphase, oldevent)
%
% This function estimates oscillatory burst frequency and phase by curve
% fitting. Linear and logarithmic fits are performed, and the version with
% the least RMS phase error is returned.
%
% "hilfreq" contains input signal instantaneous frequency samples.
% "hilphase" contains input signal instantaneous phase samples.
% "oldevent" is a record structure per EVENTFORMAT.txt. Required fields are:
%   "sampstart":  Sample index in the original recording waveform
%                 corresponding to event time 0.
%   "duration":   Time between the start and end of the event. This is where
%                 the curve fit is performed.
%   "samprate":   Number of samples per second in the input waveform.
%
% "newevent" is a record structure per EVENTFORMAT.txt. It contains the
% fields of "oldevent", as well as the following:
%   "f1":     Burst frequency at nominal start.
%   "f2":     Burst frequency at nominal stop.
%   "p1":     Burst phase at nominal start.
%   "p2":     Burst phase at nominal stop.
%   "ftype":  Frequency ramp type (set to "linear").
%
% "error" is the RMS phase error (with phase error being the difference
%   between original and reconstructed phases wrapped to -pi..pi).


% Call both fit functions.

[ eventlin, errlin ] = ...
  wlProc_fitFreqPhaseLinear(hilfreq, hilphase, oldevent);

[ eventlog, errlog ] = ...
  wlProc_fitFreqPhaseLogarithmic(hilfreq, hilphase, oldevent);


% Default to linear.

newevent = eventlin;
error = errlin;


% Switch to logarithmic if that gave a better result.

if errlog < errlin

  newevent = eventlog;
  error = errlog;

end


%
% Done.

end


%
% This is the end of the file.
