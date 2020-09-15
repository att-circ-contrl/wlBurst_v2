function [ newftdata cropdefs ] = wlFT_trimTrials(oldftdata, limitsfunc)

% function [ newftdata cropdefs ] = wlFT_trimTrials(oldftdata, limitsfunc)
%
% This function truncates trial records to limits computed by "limitsfunc",
% adjusting "sampleinfo" appropriately.
%
% "oldftdata" points to a Field Trip data structure to process.
% "limitsfunc" is a function handle for computing the region of interest for
%   each trial (with a sample index of "1" being the first sample in the
%   trial). This has the form:  [ firstsample lastsample ] = ...
%     limitsfunc(thistrial, sampleinfo_row, trialinfo_row)
%
% The intention is that "limitsfunc" may do anything from echoing the original
% trial size to reporting bounds recorded in "trialinfo" to performing
% artifact detection in the trial waveform directly.
%
% "newftdata" is a modified Field Trip data structure with cropped trials.
% "cropdefs" is an Nx2 array containing each original trial's cropping limits.


newftdata = oldftdata;
cropdefs = [];

for tidx = 1:length(oldftdata.trial)

  thistrial = oldftdata.trial{tidx};
  thistime = oldftdata.time{tidx};

  oldlength = length(thistrial);

  [ firstidx lastidx ] = limitsfunc( thistrial, ...
    oldftdata.sampleinfo(tidx,:), oldftdata.trialinfo(tidx,:) );

  cropdefs(tidx,1) = firstidx;
  cropdefs(tidx,2) = lastidx;

  newftdata.trial{tidx} = thistrial(:,firstidx:lastidx);
  newftdata.time{tidx} = thistime(firstidx:lastidx);

  newftdata.sampleinfo(tidx,1) = oldftdata.sampleinfo(tidx,1) ...
    + firstidx - 1;
  newftdata.sampleinfo(tidx,2) = oldftdata.sampleinfo(tidx,2) ...
    + lastidx - oldlength;

end


%
% Done.

end


%
% This is the end of the file.
