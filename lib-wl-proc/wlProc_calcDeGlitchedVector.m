function newvec = wlProc_calcDeGlitchedVector(oldvec, maxglitch, maxdrop)

% function newvec = wlProc_calcDeGlitchedVector(oldvec, maxglitch, maxdrop)
%
% This function removes spurious gaps (drop-outs) and brief events (glitches)
% in a one-dimensional logical array. Durations are specified as sample
% counts.
%
% "oldvec" is the vector to process. Elements should be "true" or "false".
% "maxglitch" is the longest event duration to reject as spurious.
% "maxdrop" is the longest gap duration within an event to reject as spurious.
%
% "newvec" is a modified version of "oldvec" with glitches and drop-outs
%   removed.


% Remove drop-outs first, then remove remaining glitches.
% This errs on the side of giving us longer events.


% Initialize.

newvec = oldvec;


% Look for high-to-low transitions followed by low-to-high transitions.
% If they're not longer than a drop-out, paper over them.

foundhilo = false;
for sidx = 2:length(oldvec)

  if newvec(sidx-1) && ~newvec(sidx)

    foundhilo = true;
    lasthilo = sidx;  % Index of the first zero.

  elseif foundhilo && newvec(sidx) && ~newvec(sidx-1)
    if (sidx - lasthilo) <= maxdrop

      % This is a short drop-out. Fill it in.
      newvec(lasthilo:sidx-1) = true;

    end
  end

end


% Look for low-to-high transitions followed by high-to-low transitions.
% If they're not longer than a glitch, remove them.

foundlohi = false;
for sidx = 2:length(newvec)

  if newvec(sidx) && ~newvec(sidx-1)

    foundlohi = true;
    lastlohi = sidx;  % Index of the first one.

  elseif foundlohi && newvec(sidx-1) && ~newvec(sidx)
    if (sidx - lastlohi) <= maxglitch

      % This is a short glitch. Erase it.
      newvec(lastlohi:sidx-1) = false;

    end
  end

end


%
% Done.

end

%
% This is the end of the file.
