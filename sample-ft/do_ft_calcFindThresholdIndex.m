function idxval = do_ft_calcFindThresholdIndex(dbval, dblist)

% function idxval = do_ft_calcFindThresholdIndex(dbval, dblist)
%
% This function looks up the threshold array index corresponding to a given
% threshold dB value. The array is sorted in ascending order.
%
% "dbval" is the dB value to look up.
% "dblist" is the master list of threshold dB values, in ascending order.
%
% "idxval" is the entry index in "dblist" of the closest value to "dbval".

bestidx = 1;
bestval = dblist(1);
besterr = (bestval - dbval)^2;

for thisidx = 2:length(dblist)

  thisval = dblist(thisidx);
  thiserr = (thisval - dbval)^2;

  if thiserr < besterr

    bestidx = thisidx;
    bestval = thisval;
    besterr = thiserr;

  end

end

idxval = bestidx;

%
% This is the end of the file.
