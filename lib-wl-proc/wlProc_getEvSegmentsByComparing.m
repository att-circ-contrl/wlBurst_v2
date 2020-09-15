function events = wlProc_getEvSegmentsByComparing( ...
  databigger, datasmaller, samprate, threshfactor, maxglitch, maxdrop);

% function events = wlProc_getEvSegmentsByComparing( ...
%   databigger, datasmaller, samprate, threshfactor, maxglitch, maxdrop);
%
% This function identifies the location of events in a data stream, returning
% a list of skeletal putative event records. Events are found by comparing
% two input signals, flagging events when the ratio of the larger to the
% smaller exceeds some threshold.
%
% Gaps between events that are shorter than "maxdrop" are removed, after which
% isolated events that are shorter than "maxglitch" are also removed.
%
% This is intended to be used as a helper function, called by a variety of
% detection routines with several different derived signals as input.
%
% "databigger" is the larger-valued data trace to examine.
% "datasmaller" is the smaller-valued data trace to examine.
% "samprate" is the number of samples per second in the signal data.
% "threshfactor" is the amount by which the larger signal must exceed the
%   smaller signal for an event to occur.
% "maxglitch" is the longest event duration to reject as spurious.
% "maxdrop" is the longest gap duration within an event to reject as spurious.
%
% "events" is an array of event record structures following the conventions
%   given in EVENTFORMAT.txt. Only the following fields are provided:
%
%   "sampstart":  Sample index in "data" corresponding to event nominal start.
%   "duration":   Time between burst nominal start and burst nominal stop.
%   "samprate":   Samples per second in the signal data.


% Figure out which portions are below-threshold.

detectvector = databigger > (datasmaller * threshfactor);


% Remove drop-outs first, then remove remaining glitches.
% This errs on the side of giving us longer, less-accurate events.

% FIXME - There's probably a way to use built-in functions for this.

dropoutsamps = round(maxdrop * samprate);
glitchsamps = round(maxglitch * samprate);

evcount = 0;

% Look for high-to-low transitions followed by low-to-high transitions.
% If they're not longer than a drop-out, paper over them.

foundhilo = false;
for sidx = 2:length(detectvector)

  if detectvector(sidx-1) && ~detectvector(sidx)

    foundhilo = true;
    lasthilo = sidx;  % Index of the first zero.

  elseif foundhilo && detectvector(sidx) && ~detectvector(sidx-1)
    if (sidx - lasthilo) <= dropoutsamps

      % This is a short drop-out. Fill it in.
      detectvector(lasthilo:sidx-1) = 1;

    end
  end

end


% Look for low-to-high transitions followed by high-to-low transitions.
% If they're longer than a glitch, store them as events.

foundlohi = false;
for sidx = 2:length(detectvector)

  if detectvector(sidx) && ~detectvector(sidx-1)

    foundlohi = true;
    lastlohi = sidx;  % Index of the first one.

  elseif foundlohi && detectvector(sidx-1) && ~detectvector(sidx)
    if (sidx - lastlohi) > glitchsamps

      % This is a long enough detection to be recorded.
      thisevent.sampstart = lastlohi;
      thisevent.duration = (sidx - lastlohi) / samprate;
      thisevent.samprate = samprate;
      evcount = evcount + 1;
      events(evcount) = thisevent;

    end
  end

end


% Make sure we have a return value.

if 1 > evcount
  events = [ ];
end


% Done.

end

%
% This is the end of the file.
