function [ fp fn tp matchlist fplist fnlist ] = ...
  wlProc_evalEventsVsTruth(evtruth, evtest, bandlim, snrlim, ...
    comparefunc)

% function [ fp fn tp matchlist fplist fnlist ] = ...
%   wlProc_evalEventsVsTruth(evtruth, evtest, bandlim, snrlim, ...
%     comparefunc)
%
% This function compares an event list to a "ground truth" event list.
% Only events within a specified frequency band are considered. Match rate
% statistics are computed and a list of matching event pairs is returned.
% Event record format is per EVENTFORMAT.txt.
%
% "evtruth" is a list of ground truth event records.
% "evtest" is a list of event records to test.
% "bandlim" [min max] is the frequency band for events of interest.
% "snrlim" [min max] is the burst SNR range for events of interest.
% "comparefunc" is a function handle for an event comparison function, as
%   described in COMPAREFUNC.txt. This has the form:
%     [ ismatch distance ] = comparefunc(evfirst, evsecond)
%
% "fp" is the false positive count (evtest events that aren't in evtruth).
% "fn" is the false negative count (evtruth events that aren't in evtest).
% "tp" is the true positive count (events in both evtest and evtruth).
% "matchlist" is a list of structures containing matching event pairs:
%   "truth":  The matching event from evtruth.
%   "test":   The matching event from evtest.
% "fplist" is a list of in-band "evtest" event structures that didn't match.
% "fnlist" is a list of in-band "evtruth" event structures that didn't match.


% FIXME - Diagnostics.

if false
disp(sprintf(':::Called with freq %.1f..%.1f Hz SNR %.1f..%.1f dB.', ...
  bandlim(1), bandlim(2), snrlim(1), snrlim(2) ));
end


% Initialize.

fp = 0;
fn = 0;
tp = 0;
matchcount = 0;


% We're doing this in two passes.

% The best algorithm checks all O(N^2) match candidates, finds the global
% best match, records that, removes the two matching event records, and
% repeats the entire process. This is O(N^3) total, which we don't want.

% What we do instead is build a list of all match candidates that are in
% range of each other. This is O(N^2). Because most events are out of range
% of each other, the resulting list size is O(N). We iterate on _that_ list,
% removing candidates as they're chosen, which is O(N^2).


%
%
% First pass: Build the list of candidate matches that are in range of
% each other.


candcount = 0;

for truthidx = 1:length(evtruth)

  thistruth = evtruth(truthidx);

  for testidx = 1:length(evtest)

    thistest = evtest(testidx);

    [ ismatch thisdist ] = comparefunc(thistruth, thistest);

    % If this event passes the match criteria, record it.
    if ismatch

      candcount = candcount + 1;
      candlist(candcount) = ...
        struct('truth', truthidx, 'test', testidx, 'distance', thisdist);

    end

  end

end

% If we didn't find any candidates, initialize the candidate list anyways.

if 1 > candcount
  candlist = [ ];
end


%
%
% Second pass: Record and remove the best candidate pair, until we run out
% of candidates.


% Initialize event eligibility scratchpads.

oktruth(1:length(evtruth)) = true;
oktest(1:length(evtest)) = true;


% Iterate until we can't extract any more matches.

havecandidate = true;

while havecandidate

  % Walk through the candidate list, and find the best candidate left.

  havecandidate = false;
  bestdistance = inf;
  clear bestcand;

  for cidx = 1:length(candlist)

    thiscand = candlist(cidx);

    if oktruth(thiscand.truth) && oktest(thiscand.test) ...
      && (thiscand.distance < bestdistance)

      havecandidate = true;
      bestdistance = thiscand.distance;
      bestcand = thiscand;

    end

  end

  % If we found a candidate, add it to the match list and remove its events.

  if havecandidate

    oktruth(bestcand.truth) = false;
    oktest(bestcand.test) = false;

    matchcount = matchcount + 1;
    prematchlist(matchcount) = ...
      struct('truth', bestcand.truth, 'test', bestcand.test);
  end

end

% Make sure we have a list, even if it's empty.
if 1 > matchcount
  prematchlist = [ ];
end


%
% Third pass: Compute statistics for in-band events only.

% We have to prune after finding matches; pruning the candidate list ahead
% of time results in some true detections being flagged as false negatives.

% Reinitialize event eligibility scratchpads.
% Ground truth events are only eligible if they're in-band.
% Test events are eligible if they're in-band or paired with an in-band GT.

oktruth(1:length(evtruth)) = false;
oktest(1:length(evtest)) = false;

for truthidx = 1:length(evtruth)

  thistruth = evtruth(truthidx);

  % Nominal frequency is sqrt(f1 * f2) = exp(mean([log(f1) log(f2)])).
  fnom = sqrt(thistruth.f1 * thistruth.f2);

  if (fnom >= bandlim(1)) && (fnom <= bandlim(2)) ...
    && (thistruth.snr >= snrlim(1)) && (thistruth.snr <= snrlim(2))
    oktruth(truthidx) = true;
  end

end

for testidx = 1:length(evtest)

  thistest = evtest(testidx);

  % Nominal frequency is sqrt(f1 * f2) = exp(mean([log(f1) log(f2)])).
  fnom = sqrt(thistest.f1 * thistest.f2);

  if (fnom >= bandlim(1)) && (fnom <= bandlim(2)) ...
    && (thistest.snr >= snrlim(1)) && (thistest.snr <= snrlim(2))
    oktest(testidx) = true;
  end

end


% FIXME - Diagnostics.

if false
disp( ...
  sprintf('...Before filters: %d true events, %d detected, %d matches.', ...
  length(evtruth), length(evtest), length(prematchlist) ));
disp( ...
  sprintf('...After cut, before grandfathering: %d true events, %d detected.', ...
  sum(oktruth), sum(oktest) ));
end


% Record matches where ground truth passes filtering.
% Grandfather in test events that are part of these matches.
% Build false-event checklists while we're at it.

matchcount = 0;

falsetruth = oktruth;
falsetest = oktest;

for midx = 1:length(prematchlist)

  thistruth = prematchlist(midx).truth;
  thistest = prematchlist(midx).test;

  if oktruth(thistruth)
    oktest(thistest) = true;

    matchcount = matchcount + 1;
    matchlist(matchcount) = ...
      struct( 'truth', evtruth(thistruth), 'test', evtest(thistest) );

    falsetruth(thistruth) = false;
    falsetest(thistest) = false;
  end

end

truthtotal = sum(oktruth);
testtotal = sum(oktest);


% Record non-matching records (in-band but didn't match).
% We have acceptance vectors for these already.

fplist = evtest(falsetest);
fnlist = evtruth(falsetruth);


% FIXME - Diagnostics.

if false
disp( ...
  sprintf('...After cut: %d true events, %d detected, %d matches.', ...
  sum(oktruth), sum(oktest), matchcount ));
end


% Calculate match statistics.

fp = testtotal - matchcount;
fn = truthtotal - matchcount;
tp = matchcount;


% FIXME - Sanity check.

if fp ~= length(fplist)
  disp( sprintf('### FP count mismatch (count %d, list %d).', ...
    fp, length(fplist)) );
end

if fn ~= length(fnlist)
  disp( sprintf('### FN count mismatch (count %d, list %d).', ...
    fn, length(fnlist)) );
end


%
%
% If we don't have any matches, return an empty list.

if 1 > matchcount
  matchlist = [ ];
end

%
% Done.

end

%
% This is the end of the file.
