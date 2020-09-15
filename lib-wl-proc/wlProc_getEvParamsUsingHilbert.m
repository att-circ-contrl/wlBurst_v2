function newevents = wlProc_getEvParamsUsingHilbert(data, samprate, ...
  hilmag, hilfreq, hilphase, oldevents, gridsteps)

% function newevents = wlProc_getEvParamsUsingHilbert(data, samprate, ...
%   hilmag, hilfreq, hilphase, oldevents, gridsteps)
%
% This function estimates oscillatory burst parameters given a list of
% putative event locations and a signal waveform. An updated list of events
% is generated.
% NOTE - The signal waveform should already be band-pass filtered.
% The "UsingHilbert" implementation takes the analytic signal components as
% input and curve-fits to them directly.
%
% "data" is the data trace to examine. This is typically band-pass filtered.
% "samprate" is the number of samples per second in the signal data.
% "hilmag" is the instantaneous magnitude of the analytic signal.
% "hilfreq" is the instantaneous frequency of the analytic signal.
% "hilphase" is the instantaneous phase of the analytic signal.
% "oldevents" is the input event list. Only the "sampstart", "duration",
%   and "samprate" fields must be present.
% "gridsteps" is an optional argument specifying the number of steps to use
%   when sweeping roll-on and roll-off times during curve fitting.
%
% "newevents" is an array of event record structures following the
%   conventions given in EVENTFORMAT.txt. Curve fit parameters are generated,
%   but "times", "wave", "mag", "freq", and "phase" are left unset. The
%   "auxwaves" and "auxdata" fields are initialized as empty if not present.


%
% Initialize.

if ~exist('gridsteps', 'var')
  % Set a reasonable default.
  gridsteps = 5;
end


%
% Walk through the event list, building new events.

evcount = length(oldevents);

for evidx = 1:evcount

  thisnewevent = oldevents(evidx);


  % Initialize "auxwaves" and "auxdata" if we don't already have them.

  if ~isfield(thisnewevent, 'auxwaves')
    thisnewevent.auxwaves = struct();
  end

  if ~isfield(thisnewevent, 'auxdata')
    thisnewevent.auxdata = struct();
  end


  % Specify fit type.
  thisnewevent.paramtype = 'chirpramp';


  % Fit the envelope.

  thisnewevent = wlProc_fitAmpGrid(hilmag, thisnewevent, gridsteps);


  % Fit frequency and phase, now that we have final endpoints.

  thisnewevent = wlProc_fitFreqPhase(hilfreq, hilphase, thisnewevent);


  % Done. Record the new event.

  newevents(evidx) = thisnewevent;

end


% Make sure we have an event list.

if 1 > evcount
  newevents = [ ];
end


% Calculate signal-to-noise ratios of the detected events.

newevents = wlProc_calcEventSNRs(data, samprate, newevents);


%
% Done.

end

%
% This is the end of the file.
