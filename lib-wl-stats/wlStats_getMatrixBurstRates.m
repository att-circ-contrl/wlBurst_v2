function [ rate_avg rate_dev rate_sem ] = wlStats_getMatrixBurstRates( ...
  detectmatrix, time_bins_sec, bootcount )

% function [ rate_avg rate_dev rate_sem ] = wlStats_getMatrixBurstRates( ...
%   detectmatrix, time_bins_sec, bootcount )
%
% This computes the average burst rate across trials within a set of
% time bins. Statistics are estimated via bootstrapping.
%
% "Burst rate" is the average number of bursts overlapping a given time
% window. In  most cases, this will be very much less than 1, and can be
% interpreted as "burst probability" within that window.
%
% "detectmatrix" is an event matrix structure per EVMATRIX.txt.
% "time_bins_sec" is a cell array. Each cell contains a [ min max ] time pair
%   specifying time bin extents in seconds.
% "bootcount" is the number of distributions to generate when estimating the
%   SEM for the average burst rates. As a special case, this may be 'normal'
%   to estimate it by dividing the deviation by the square root of the number
%   of trials.
%
% "rate_avg" is a matrix indexed by (bidx, cidx, widx) that holds the burst
%   rate (expected number of bursts) observed for each band, channel, and
%   time window, averaged across trials.
% "rate_dev" is a matrix per "rate_avg" holding the standard deviation of the
%   burst rate across trials.
% "rate_sem" is a matrix per "rate_avg" holding the standard error of the
%   mean of the burst rate (the estimated standard deviation of the value
%   of "rate_avg").


% Get dimensions and initialize.

evmatrix = detectmatrix.events;
wavematrix = detectmatrix.waves;

[ bandcount trialcount chancount ] = size(evmatrix);

wincount = length(time_bins_sec);

rate_avg = nan([ bandcount chancount wincount ]);
rate_dev = rate_avg;
rate_sem = rate_avg;



% Iterate event lists.

for bidx = 1:bandcount
  for cidx = 1:chancount

    % First pass: Get per-trial event rates.
    % We'll normally either have 0 or 1 event per window.

    ratescratch = nan( [ trialcount wincount ] );

    for tidx = 1:trialcount
      thisevlist = evmatrix{bidx, tidx, cidx};
      thistimeseries = wavematrix{bidx, tidx, cidx}.fttimes;

      for widx = 1:wincount
        thiswin = time_bins_sec{widx};

        % Clamp the time window to the actual time range.
        thiswin = [ min(thiswin) max(thiswin) ];
        thiswin(1) = max( thiswin(1), min(thistimeseries) );
        thiswin(2) = min( thiswin(2), max(thistimeseries) );

        thiswinevents = ...
          wlAux_selectEventsByTime( thisevlist, thiswin, thistimeseries );
        thisrate = length(thiswinevents);

% FIXME - Normalizing by window size doesn't give bursts per second!
% We'd have to factor in burst duration.
%        % Rate is event count divided by window duration.
%        thiswinsize = max(thiswin) - min(thiswin);
%        thisrate = thisrate / thiswinsize;

        ratescratch(tidx,widx) = thisrate;
      end
    end


    % Second pass: Get statistics across trials.

    for widx = 1:wincount
      thisratelist = ratescratch(:,widx);
      [ thisavg thisdev thissem ] = ...
        wlStats_getBootstrappedStats( thisratelist, bootcount );

      rate_avg(bidx,cidx,widx) = thisavg;
      rate_dev(bidx,cidx,widx) = thisdev;
      rate_sem(bidx,cidx,widx) = thissem;
    end

  end
end



% Done.

end


%
% This is the end of the file.
