function newmatrix = wlAux_pruneMatrix(oldmatrix, passfunc)

% function newmatrix = wlAux_pruneMatrix(oldmatrix, passfunc)
%
% This function removes a subset of the event records from an event matrix.
% Events for which "passfunc" returns "true" are kept; events for which
% "passfunc" returns "false" are removed.
% Event matrix format is described in EVMATRIX.txt.
%
% "oldmatrix" is an event matrix containing events to process.
% "passfunc" is a function handle for an event evaluation function, with
%   the form:  result = passfunc(event)
%
% "newmatrix" is an event matrix containing only events for which "passfunc"
%   returned "true".

[ bandcount trialcount chancount ] = size(oldmatrix.events);

newmatrix = oldmatrix;
newmatrix.events = {};

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount

      clear newlist;
      newcount = 0;

      oldlist = oldmatrix.events{bidx, tidx, cidx};
      evcount = length(oldlist);

      for eidx = 1:evcount
        thisev = oldlist(eidx);
        if passfunc(thisev)
          newcount = newcount + 1;
          newlist(newcount) = thisev;
        end
      end

      if 1 > newcount
        newlist = [];
      end

      newmatrix.events{bidx, tidx, cidx} = newlist;

    end
  end
end


%
% Done.

end


%
% This is the end of the file.
