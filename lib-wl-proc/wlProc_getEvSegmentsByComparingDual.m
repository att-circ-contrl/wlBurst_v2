function events = wlProc_getEvSegmentsByComparingDual( ...
  databigger, datasmaller, samprate, ...
  threshfactpeak, threshfactend, maxglitch, maxdrop);

% function events = wlProc_getEvSegmentsByComparingDual( ...
%   databigger, datasmaller, samprate, ...
%   threshfactpeak, threshfactend, maxglitch, maxdrop);
%
% This function identifies the location of events in a data stream, returning
% a list of skeletal putative event records. Events are found by comparing
% two input signals, flagging event regions where the ratio of the larger to
% the smaller exceeds some threshold. Event endpoints are the nearest points
% where the ratio of the larger to the smaller exceeds a different (lower)
% threshold.
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
% "threshfactpeak" is the amount by which the larger signal must exceed the
%   smaller signal for an event to occur.
% "threshfactend" is the amount by which the larger signal must exceed the
%   smaller signal at event endpoints
% "maxglitch" is the longest event duration to reject as spurious.
% "maxdrop" is the longest gap duration within an event to reject as spurious.
%
% "events" is an array of event record structures following the conventions
%   given in EVENTFORMAT.txt. Only the following fields are provided:
%
%   "sampstart":  Sample index in "data" corresponding to event nominal start.
%   "duration":   Time between burst nominal start and burst nominal stop.
%   "samprate":   Samples per second in the signal data.


% Figure out which portions are above- and below-threshold.

detectvecpeak = databigger > (datasmaller * threshfactpeak);
detectvecend = databigger > (datasmaller * threshfactend);


% Calculate de-glitched vectors.

dropoutsamps = round(maxdrop * samprate);
glitchsamps = round(maxglitch * samprate);

detectvecpeak = ...
  wlProc_calcDeGlitchedVector(detectvecpeak, glitchsamps, dropoutsamps);

% FIXME - Tweaking endpoint detection.
if false

  % Old way: De-glitch endpoint vector.
  % This gives us ranges that are too long.
  detectvecend = ...
    wlProc_calcDeGlitchedVector(detectvecend, glitchsamps, dropoutsamps);

else

  % New way: Don't de-glitch, but do project the peak vector on to the
  % endpoint vector. This guarantees that we straddle the peak but hopefully
  % doesn't over-detect the lobe we're processing.
  % It may under-detect in certain cases.

  detectvecend = detectvecend | detectvecpeak;

end


% Find above-end runs that have at least one above-peak run in them.
% These are events.


evcount = 0;


% Look for low-to-high transitions followed by high-to-low transitions in
% the endpoint detection vector.

foundlohi = false;
for sidx = 2:length(detectvecend)

  if detectvecend(sidx) && ~detectvecend(sidx-1)

    % This is the start of a potential event.

    foundlohi = true;
    lastlohi = sidx;  % Index of the first "true" element.

  elseif foundlohi && detectvecend(sidx-1) && ~detectvecend(sidx)

    % This is the end of a potential event (just past the end).
    % See if it has above-peak elements.

    peaksubset = detectvecpeak(lastlohi:sidx-1);

    if 0 < sum(peaksubset)

      % There's a peak that rises above the detection threshold, so this is
      % a real event.

      % Record endpoints.

      thisevent.sampstart = lastlohi;
      thisevent.duration = (sidx - lastlohi) / samprate;
      thisevent.samprate = samprate;

      if false

        % FIXME - Tweak this event to have roll-on and roll-off.
        % This is intended to make our other fitting routines behave better.

        % FIXME - This doesn't actually help; instead we get too-short events.
        % The original way - nominal 50% roll points at the detected
        % _endpoints_ - actually works best.

        rolltime = 0.2 * thisevent.duration;
        thisevent.rollon = rolltime;
        thisevent.rolloff = rolltime;
        thisevent.duration = thisevent.duration - rolltime;
        thisevent.sampstart = thisevent.sampstart ...
          + round( 0.5 * rolltime * samprate );

      end

      % FIXME - Debugging; save the decision vectors as auxiliary waves.

      if true

        % FIXME - Kludge this for context calculations.
        fnom = 2.0 / thisevent.duration;

        thisevent.auxwaves = struct();

        [ conwave, contimes ] = wlAux_getContextTrace(databigger, ...
          samprate, 2, 2, fnom, thisevent.duration, thisevent.sampstart);
        thisevent.auxwaves.seglargewave = conwave;
        thisevent.auxwaves.seglargetimes = contimes;

        [ conwave, contimes ] = wlAux_getContextTrace(datasmaller, ...
          samprate, 2, 2, fnom, thisevent.duration, thisevent.sampstart);
        thisevent.auxwaves.segsmallwave = conwave;
        thisevent.auxwaves.segsmalltimes = contimes;

        [ conwave, contimes ] = wlAux_getContextTrace(detectvecpeak * 1.0, ...
          samprate, 2, 2, fnom, thisevent.duration, thisevent.sampstart);
        thisevent.auxwaves.segpeakwave = conwave;
        thisevent.auxwaves.segpeaktimes = contimes;

        [ conwave, contimes ] = wlAux_getContextTrace(detectvecend * 1.0, ...
          samprate, 2, 2, fnom, thisevent.duration, thisevent.sampstart);
        thisevent.auxwaves.segendwave = conwave;
        thisevent.auxwaves.segendtimes = contimes;

      end

      % Save this event.

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
