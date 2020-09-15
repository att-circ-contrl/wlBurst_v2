function [ newevent, error ] = wlProc_fitAmpGrid(hilmag, oldevent, gsteps)

% function [ newevent, error ] = wlProc_fitAmpGrid(hilmag, oldevent, gsteps)
%
% This function estimates oscillatory burst amplitude by curve fitting a
% logarithmic or linear ramp in the region of interest. Roll-on and roll-off
% are chosen via a brute force grid search with the indicated number of steps.
%
% "hilmag" contains analytic signal instantaneous magnitude samples.
% "oldevent" is a record structure per EVENTFORMAT.txt. Required fields are:
%   "sampstart":  Sample index in the original recording waveform
%                 corresponding to event time 0.
%   "duration":   Time between the start and end of the event. This is where
%                 the curve fit is performed.
%   "samprate":   Number of samples per second in the input waveform.
%
% "gsteps" is the number of steps to use when sweeping each of the roll times.
%
% "newevent" is a record structure per EVENTFORMAT.txt. It contains the
% fields of "oldevent", as well as the following:
%   "a1":       Burst amplitude at nominal start.
%   "a2":       Burst amplitude at nominal stop.
%   "atype":    Amplitude ramp type.
%   "rollon":   Cosine roll-on time.
%   "rolloff":  Cosine roll-off time.
%
% "error" is the RMS error between the fitted amplitude and the magnitude
%   of the analytic signal.


%
% Calculate search parameters.

% FIXME - Assume our nominal duration was chosen for a 20% roll-off.
% I.e. pad the duration by 10% on each side.

samptotal = round(oldevent.duration * oldevent.samprate);
sampnudge = round(0.1 * samptotal);
sampstartpoint = oldevent.sampstart - sampnudge;
sampendpoint = oldevent.sampstart + samptotal + sampnudge;

% Clip the range if we're past the end of the input waveform.
sampstartpoint = max(1, sampstartpoint);
sampendpoint = min(length(hilmag), sampendpoint);

% NOTE - Using floor() to guarantee that our roll-on and roll-off don't
% overlap.
sampstepsize = floor( (sampendpoint - sampstartpoint) / (1 + gsteps) );
% FIXME - Still getting tiny overlaps. Kludge it.
sampstepsize = max(0, sampstepsize - 1);


%
% Do the search.

% Fallback in case of zero search tests. Shouldn't happen.
bestevent = oldevent;
besterr = inf;

testevent = oldevent;

for startidx = 1:gsteps
  for endidx = startidx:gsteps

    % Build an event record with appropriate endpoints and roll times.

    rollonsamps = startidx * sampstepsize;
    rolloffsamps = (1 + gsteps - endidx) * sampstepsize;

    samphalfstart = sampstartpoint + floor(0.5 * rollonsamps);
    samphalfend = sampendpoint - floor(0.5 * rolloffsamps);

    testevent.sampstart = samphalfstart;
    testevent.duration = (samphalfend - samphalfstart) / testevent.samprate;
    testevent.rollon = rollonsamps / testevent.samprate;
    testevent.rolloff = rolloffsamps / testevent.samprate;


    % If this is the best candidate we've seen so far, record it.

    [ resultevent, thiserr ] = wlProc_fitAmpBasic(hilmag, testevent);

    if (thiserr < besterr)
      besterr = thiserr;
      bestevent = resultevent;
    end

  end
end


%
% Copy the best version we found.

newevent = bestevent;
error = besterr;


%
% Done.

end

%
% This is the end of the file.
