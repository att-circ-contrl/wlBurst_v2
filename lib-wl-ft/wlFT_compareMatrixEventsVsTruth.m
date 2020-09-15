function [ fp fn tp matchtruth matchtest missingtruth missingtest ] = ...
  wlFT_compareMatrixEventsVsTruth(truthmatrix, testmatrix, comparefunc, ...
  bandlim, snrlim)

% function [ fp fn tp matchtruth matchtest missingtruth missingtest ] = ...
%   wlFT_compareMatrixEventsVsTruth(truthmatrix, testmatrix, comparefunc, ...
%   bandlim, snrlim)
%
% This function compares a detected event matrix to a "ground truth" event
% matrix. Only events within a specified frequency band and SNR range are
% considered. Match rate statistics are computed and matrices containing
% matching and non-matching event pairs are returned. Event matrix format
% is per EVMATRIX.txt.
%
% "truthmatrix" is an event matrix containing ground-truth events.
% "testmatrix" is an event matrix containing putative detected events.
% "comparefunc" is a function handle for an event comparison function, as
%   described in COMPAREFUNC.txt. This has the form:
%     [ ismatch distance ] = comparefunc(evfirst, evsecond)
% "bandlim" [min max] is the frequency band for events of interest. This is
%   optional; omitting it accepts all frequencies.
% "snrlim" [min max] is the burst SNR range (in dB) for events of interest.
%   This is optional; omitting it accepts all SNRs.
%
% "fp(bidx, tidx, cidx)" is the false positive count (bad putative events).
% "fn(bidx, tidx, cidx)" is the false negative count (unmatched truth events).
% "tp(bidx, tidx, cidx)" is the true positive count (matched events).
% "matchtruth" is an event matrix containing copies of ground truth events
%   that matched.
% "matchtest" is an event matrix containing copies of putative events that
%   matched.
% "missingtruth" is an event matrix containing copies of ground truth events
%   that did not match (false negatives).
% "missingtest" is an event matrix containing copies of putative events that
%   did not match (false positives).


%
% Initialize.

if ~exist('bandlim', 'var')
  bandlim = [ -inf inf ];
end

if ~exist('snrlim', 'var')
  snrlim = [ -inf inf ];
end

[ bandcount trialcount chancount ] = size(testmatrix.events);

fp = zeros(bandcount, trialcount, chancount);
fn = fp;
tp = fp;

matchtruth = truthmatrix;
matchtruth.events = {};
matchtest = testmatrix;
matchtest.events = {};

missingtruth = matchtruth;
missingtest = matchtest;


%
% Wrap the single-list algorithm.

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount

      truthlist = truthmatrix.events{bidx, tidx, cidx};
      testlist = testmatrix.events{bidx, tidx, cidx};


      % Find the longest event, so that we can pick a bin size.

      maxdur = 0;
      for eidx = 1:length(truthlist)
        maxdur = max(maxdur, truthlist(eidx).duration);
      end
      for eidx = 1:length(testlist)
        maxdur = max(maxdur, testlist(eidx).duration);
      end

      binsecs = round(maxdur * 3);
      binsecs = max(1,binsecs);


      % Find this cell's statistics, and store the results.

      [ thisfp, thisfn, thistp, matchlist, fplist, fnlist ] = ...
        wlProc_evalEventsVsTruthBinned(truthlist, testlist, bandlim, ...
          snrlim, comparefunc, binsecs, 1);

      fp(bidx, tidx, cidx) = thisfp;
      fn(bidx, tidx, cidx) = thisfn;
      tp(bidx, tidx, cidx) = thistp;

      missingtruth.events{bidx, tidx, cidx} = fnlist;
      missingtest.events{bidx, tidx, cidx} = fplist;

      for eidx = 1:length(matchlist)
        matchtruth.events{bidx, tidx, cidx}(eidx) = matchlist(eidx).truth;
        matchtest.events{bidx, tidx, cidx}(eidx) = matchlist(eidx).test;
      end

      if 1 > length(matchlist)
        % FIXME - Not the correct type, but it doesn't matter for empty.
        matchtruth.events{bidx, tidx, cidx} = [];
        matchtest.events{bidx, tidx, cidx} = [];
      end

    end
  end
end


%
% Done.

end


%
% This is the end of the file.
