function newlist = wlAux_selectEventsByTime( oldlist, timerange, timestamps )

% function newlist = wlAux_selectEventsByTime( oldlist, timerange, timestamps )
%
% This selects events from an event list that overlap a specified time
% range.
%
% "oldlist" is an array of event structures, per EVENTFORMAT.txt.
% "timerange" [ min max ] is the range of timestamps to accept.
% "timestamps" is a vector containing sample timestamps.
%
% "newlist" is a copy of "oldlist" containing only those events that passed
%   the time range check.


minsamp = min(find( timestamps >= min(timerange) ));
maxsamp = max(find( timestamps <= max(timerange) ));

keepmask = false(size(oldlist));

% Only proceed if at least some samples are within the requested time range.
if (~isempty(minsamp)) && (~isempty(maxsamp))

  for eidx = 1:length(oldlist)
    thisev = oldlist(eidx);

    thisstart = thisev.sampstart;
    thisend = thisstart + thisev.s2 - thisev.s1;

    keepmask(eidx) = (thisstart <= maxsamp) & (thisend >= minsamp);
  end

end

newlist = oldlist(keepmask);


% Done.

end


%
% This is the end of the file.
