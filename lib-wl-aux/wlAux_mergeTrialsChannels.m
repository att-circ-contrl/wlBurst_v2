function newmatrix = wlAux_mergeTrialsChannels(oldmatrix, comparefunc)

% function newmatrix = wlAux_mergeTrialsChannels(oldmatrix, comparefunc)
%
% This function merges an event matrix's events across trials and channels
% (so that each band has a single trial with a single channel). Duplicate
% events (as detected by "comparefunc") are merged.
% Event matrix format is described in EVMATRIX.txt.
%
% NOTE - Old "auxdata" values are discarded. An arbitrarily chosen "waves"
% entry within each band is kept as a placeholder, but should be considered
% meaningless.
%
% The only reason to merge trials this way is to consolidate the event
% list. Almost all context information is lost.
%
% NOTE - This can take O(n^2) time. Use it with caution.
%
% "oldmatrix" is an event matrix containing the events to process.
% "comparefunc" is a function handle for an event comparison function, as
%   described in COMPAREFUNC.txt. This has the form:
%     [ ismatch distance ] = comparefunc(evfirst, evsecond)
%
% "newmatrix" is an event matrix containing re-binned events.


% FIXME - Diagnostics.
dotattle = false;


%
% FIXME - Banner.

if dotattle
disp('.. Merging trials and channels.')
disp(datetime);
end


%
% Get size information.

[ bandcount trialcount chancount ] = size(oldmatrix.events);


%
% Get bin information.

minfreq = min(oldmatrix.bandinfo(1).band);
for bidx = 1:bandcount
  thismin = min(oldmatrix.bandinfo(bidx).band);
  minfreq = min(thismin, minfreq);
end
bintime = round(20 / minfreq);
bintime = max(1, bintime);


if false && dotattle

% FIXME - Diagnostics.
disp(sprintf('++ Bin size %d seconds (min freq %.1f Hz)', bintime, minfreq));


% FIXME - Diagnostics.
evtotal = 0;
for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount
      evtotal = evtotal + length(oldmatrix.events{bidx, tidx, cidx});
    end
  end
end
disp(sprintf( '++ Before merge: %dx%dx%d with %d events.', ...
  bandcount, trialcount, chancount, evtotal ));

end


%
% Iterate across bands, merging trials and channels within them.

% NOTE - The "merge event lists" function accepts 1d lists, so send it
% slices rather than individual lists.

% NOTE - Trials have overlapping times (we're not fixing times), and
% channels have overlapping times no matter what. Event list merging
% may bog down significantly.


eventsbyband = {};

for bidx = 1:bandcount

  % Use parentheses to get a slice of a cell array; don't dereference.
  scratchlist = wlAux_mergeEventLists(oldmatrix.events(bidx,1,:), ...
    comparefunc, bintime, 1);

  for tidx = 2:trialcount

    templist = wlAux_mergeEventLists(oldmatrix.events(bidx,tidx,:), ...
      comparefunc, bintime, 1);

    scratchlist = wlAux_mergeEventLists({ [ templist scratchlist ] }, ...
      comparefunc, bintime, 1);

  end

  newevents{bidx,1,1} = scratchlist;

  % FIXME - Diagnostics.
%  disp(sprintf( '++ Band %d:  %d entries', bidx, length(scratchlist) ));

end


%
% Build the new event matrix structure.

for bidx = 1:bandcount

  newaux{bidx,1,1} = struct();
  newwaves{bidx,1,1} = oldmatrix.waves{bidx,1,1};

end

% Remember to wrap cell arrays in {} in the struct() call.

newmatrix = struct( ...
  'bandinfo', oldmatrix.bandinfo, 'samprate', oldmatrix.samprate, ...
  'segconfigbyband', {oldmatrix.segconfigbyband}, ...
  'paramconfigbyband', {oldmatrix.paramconfigbyband}, ...
  'events', {newevents}, 'waves', {newwaves}, 'auxdata', {newaux});


if false && dotattle

% FIXME - Diagnostics.
[ bandcountnew trialcountnew chancountnew ] = size(newmatrix.events);
evtotal = 0;
for bidx = 1:bandcountnew
  for tidx = 1:trialcountnew
    for cidx = 1:chancountnew
      evtotal = evtotal + length(newmatrix.events{bidx, tidx, cidx});
    end
  end
end
disp(sprintf( '++ After merge: %dx%dx%d with %d events.', ...
  bandcountnew, trialcountnew, chancountnew, evtotal ));

end


%
% FIXME - Banner.

if dotattle
disp(datetime);
disp('.. Finished merging.')
end


%
% Done.

end


%
% This is the end of the file.
