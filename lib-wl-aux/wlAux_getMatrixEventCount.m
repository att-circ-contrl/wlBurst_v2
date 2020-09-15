function evcount = wlAux_getMatrixEventCount(evmatrix)

% function evcount = wlAux_getMatrixEventCount(evmatrix)
%
% This function returns the number of events in a matrix, across all bands,
% trials, and channels.
%
% "evmatrix" is an event matrix, per EVMATRIX.txt.
%
% "evcount" is the total number of events recorded in the event matrix.

[ bandcount trialcount chancount ] = size(evmatrix.events);

evcount = 0;

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount
      evcount = evcount + length(evmatrix.events{bidx, tidx, cidx});
    end
  end
end


%
% Done.

end


%
% This is the end of the file.
