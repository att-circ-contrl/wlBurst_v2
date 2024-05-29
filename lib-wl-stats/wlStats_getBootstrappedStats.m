function [ stat_mean stat_dev stat_sem ] = ...
  wlStats_getBootstrappedStats( datavals, bootcount )

% function [ stat_mean stat_dev stat_sem ] = ...
%   wlStats_getBootstrappedStats( datavals, bootcount )
%
% This computes the mean, standard deviation, and standard error of the
% mean for a set of samples. SEM is estimated via bootstrapping or by
% assuming a normal distribution.
%
% "datavals" is a vector containing data samples.
% "bootcount" is the number of distributions to generate when estimating
%   the SEM. As a special case, this may be 'normal' to estimate it by
%   dividing the deviation by the square root of the number of samples.
%
% "stat_mean" is the average (mean) sample value.
% "stat_dev" is the standard deviation of the sample values.
% "stat_sem" is the standard error of the mean (the estimated standard
%   deviation of stat_mean).


% Mean and deviation are fast to compute.

stat_mean = mean(datavals);
stat_dev = std(datavals);


% Use resampling to get the SEM.

datacount = length(datavals);

if ~ischar(bootcount)

  % Use bootstrapping. Get surrogates by drawing Nsamp samples randomly.

  meanlist = nan([ 1 bootcount ]);

  for bidx = 1:bootcount
    thisidxvec = randi( datacount, size(datavals) );
    thisproxy = datavals(thisidxvec);
    meanlist(bidx) = mean(thisproxy);
  end

  stat_sem = std(meanlist);

else

  % Fall back to 'normal' method.
  stat_sem = stat_dev / sqrt(datacount);

end



% Done.

end


%
% This is the end of the file.
