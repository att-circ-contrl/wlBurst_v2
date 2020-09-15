function newlist = wlAux_mergeEventLists(oldlistarray, ...
  comparefunc, binsecs, huntbins)

% function newlist = wlAux_mergeEventLists(oldlistarray, ...
%   comparefunc, binsecs, huntbins)
%
% This function merges multiple event lists, removing duplicates.
% Duplicates are those that match according to "comparefunc". Events are
% sorted in ascending order of "sampstart".
%
% FIXME - For now, an arbitrarily selected duplicate is kept, and the rest
% are removed. This should be upgraded to find a proper cluster average.
%
% "oldlistarray" is a cell array of event lists to merge.
% "comparefunc" is a function handle for an event comparison function, as
%   described in COMPAREFUNC.txt. This has the form:
%     [ ismatch distance ] = comparefunc(evfirst, evsecond)
% "binsecs" is the size of time bins, in seconds. Only events in nearby bins
%   are compared for duplication.
% "huntbins" is the number of bins on either side of an event to check for
%   duplicates.
%
% "newlist" is an event list containing all entries from "oldlistarray",
%   with duplicates removed, sorted in ascending order of "sampstart".


%
% First pass: Merge the lists without sorting.

% FIXME - For now, just iteratively call "evalEventsVsTruth" to merge
% successive lists.

scratchlist = [];

for lidx = 1:length(oldlistarray)

  [ fp fn tp matchlist fplist fnlist ] = wlProc_evalEventsVsTruthBinned( ...
    scratchlist, oldlistarray{lidx}, [ 0 inf ], [ -inf inf ], ...
    comparefunc, binsecs, huntbins );

  % FIXME - For the "match" cases, just take the first element of the pair.

  clear commonlist;

  for midx = 1:length(matchlist)
    % Fields are "truth" (first list) and "test" (second list).
    commonlist(midx) = matchlist(midx).truth;
  end

  if ~exist('commonlist', 'var')
    commonlist = [];
  end

  % Concatenate the lists. The result will be out-of-order.
  scratchlist = [ fnlist commonlist fplist ];

end


%
% Second pass: Sort the merged list.

if 1 > length(scratchlist)

  newlist = [];

else

  for eidx = 1:length(scratchlist)
    startlist(eidx) = scratchlist(eidx).sampstart;
  end

  [ sortedstart sortstartlut ] = sort(startlist);

  newlist = scratchlist(sortstartlut);

end


%
% Done.

end


%
% This is the end of the file.
