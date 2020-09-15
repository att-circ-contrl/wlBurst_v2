function bandevlist = wlAux_splitEventsByBand(oldlist, bandlist)

% function bandevlist = wlAux_splitEventsByBand(oldlist, bandlist)
%
% This function splits an event list into smaller lists of events that match
% the supplied frequency bands.
%
% "oldlist" is an array of event records per EVENTFORMAT.txt.
% "bandlist" is a cell array with entries containing [ low high ] band defs.
%
% "bandevlist" is a cell array containing arrays of event indices for
%   in-band event records. Indices index events in "oldlist". Bands are
%   presented in the same order as the bands in "bandlist".
%
% Getting band events themselves is straightforward: oldlist(bandevlist{band}).


%
% Figure out what our low and high bands are, for out-of-band events.

minfreq = bandlist{1}(1);
minbidx = 1;
maxfreq = bandlist{1}(2);
maxbidx = 1;

for bidx = 2:length(bandlist)

  thisband = bandlist{bidx};

  if thisband(1) < minfreq
    minfreq = thisband(1);
    minbidx = bidx;
  end

  if thisband(2) > maxfreq
    maxfreq = thisband(2);
    maxbidx = bidx;
  end

end


%
% Walk through the events, building the new event lists.
% Every event ends up _somewhere_, even if it's out-of-band.

for bidx = 1:length(bandlist)

  thisband = bandlist{bidx};
  evcount = 0;
  clear newevlist;

  for eidx = 1:length(oldlist)

    thisev = oldlist(eidx);
    fnom = sqrt(thisev.f1 * thisev.f2);

    if ( (fnom >= thisband(1)) && (fnom <= thisband(2)) ) ...
      || ( (fnom <= minfreq) && (bidx == minbidx) ) ...
      || ( (fnom >= maxfreq) && (bidx == maxbidx) )

      evcount = evcount + 1;
      newevlist(evcount) = eidx;
    end

  end

  if 1 > evcount
    newevlist = [];
  end

  bandevlist{bidx} = newevlist;

end


%
% Done.

end


%
% This is the end of the file.
