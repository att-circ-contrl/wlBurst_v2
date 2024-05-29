function binlist = wlFT_getTimeBinList(ftdata, time_bin_ms, offset)

% function binlist = wlFT_getTimeBinList(ftdata, time_bin_ms, offset)
%
% This generates a list of time bin spans that covers a set of Field Trip
% trials.
%
% "ftdata" is a ft_datatype_raw data structure produced by Field Trip.
% "time_bin_ms" is the time bin width in milliseconds.
% "offset" is 'center', 'edge', or a time in milliseconds. If it's 'center',
%   one time bin's midpoint is at t=0. If it's 'edge', one time bin starts
%   at t=0. If it's a time in milliseconds, one time bin's midpoint is at
%   that time.
%
% "binlist" is a cell array. Each cell contains a [ min max ] time pair
%   specifying the time bin extents in seconds (not milliseconds).


% Initialize.

binlist = {};


% Find one edge of our reference bin.

time_bin_radius_sec = time_bin_ms * 0.5 * 0.001;

if ischar(offset)
  if strcmp(offset, 'edge')
    offset = 0.0;
  else
    offset = - time_bin_radius_sec;
  end
else
  offset = offset - time_bin_radius_sec;
end


% Find the time extents of the trials.

mintime = inf;
maxtime = -inf;

for tidx = 1:length(ftdata.time)
  thismin = min(ftdata.time{tidx});
  thismax = max(ftdata.time{tidx});

  mintime = min(mintime, thismin);
  maxtime = max(maxtime, thismax);
end


% Bail out if we had no trials or if anything else went wrong.

if (~isfinite(mintime)) || (~isfinite(maxtime)) || (mintime > maxtime)
  return;
end


% Build a bin sequence.

timestep = 0.001 * time_bin_ms;

idxstart = floor( (mintime - offset) / timestep );
idxend = ceil( (maxtime - offset) / timestep );

edgelist = idxstart:idxend;
edgelist = (edgelist * timestep) + offset;

for eidx = 2:length(edgelist)
  binlist{eidx-1} = [ edgelist(eidx-1), edgelist(eidx) ];
end


% Done.

end


%
% This is the end of the file.
