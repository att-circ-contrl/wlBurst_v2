function newmatrix = wlFT_calcEventErrors(oldmatrix, errfunc, errlabel)

% function newmatrix = wlFT_calcEventErrors(oldmatrix, errfunc, errlabel)
%
% This function calculates reconstruction error for each detected event in
% the specified event matrix. Error is computed between the event and one or
% more context waves using the specified event function, and the resulting
% error value is stored in the specified field in each event record's
% "auxdata" structure.
%
% "oldmatrix" is the event matrix to process.
% "errfunc" is a function handle for a wave error function, as described
%   in WAVEERRFUNC.txt. This has the form:
%     error = errfunc(event, wavestruct)
% "errlabel" is the name of the field within (event).auxdata to store event
%   reconstruction error values in.
%
% "newmatrix" is a copy of "oldmatrix" with error values added.


[ bandcount, trialcount, chancount ] = size(oldmatrix.events);
newmatrix = oldmatrix;

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount

      evlist = oldmatrix.events{bidx, tidx, cidx};
      clear newevlist;

      thiswavestruct = oldmatrix.waves{bidx,tidx,cidx};

      for eidx = 1:length(evlist)
        thisev = evlist(eidx);

        % Make sure we have somewhere to store the result.
        if ~isfield(thisev, 'auxdata')
          thisev.auxdata = struct();
        end

        % Make sure we have a "wave" reconstruction.

        if ( ~isfield(thisev, 'wave') ) || ( ~isfield(thisev, 's1' ) )
          scratchlist = wlAux_getReconFromParams( [ thisev ] );
          thisev = scratchlist(1);
        end

        % Compute and store the error value.

        thiserr = errfunc(thisev, thiswavestruct);
        thisev.auxdata = setfield(thisev.auxdata, errlabel, thiserr);

        % This has to be a new list, in case we had to add "auxdata".
        newevlist(eidx) = thisev;
      end

      if 1 > length(evlist)
        newevlist = evlist;
      end

      newmatrix.events{bidx, tidx, cidx} = newevlist;

    end
  end
end


% FIXME - Go through the matrix again, replacing empty lists with a
% zero-length extract from a non-empty list, to keep types consistent.

fakelist = newmatrix.events{1,1,1};

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount
      thislist = newmatrix.events{bidx, tidx, cidx};
      if 0 < length(thislist)
        fakelist = thislist(1:0);
      end
    end
  end
end

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount
      if 1 > length(newmatrix.events{bidx, tidx, cidx})
        newmatrix.events{bidx, tidx, cidx} = fakelist;
      end
    end
  end
end



%
% Done.

end


%
%
% This is the end of the file.
