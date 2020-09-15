function [ newftdata chandefs ] = wlFT_getChanSubset(oldftdata, chanlist)

% function [ newftdata chandefs ] = wlFT_getChanSubset(oldftdata, chanlist)
%
% This function extracts a subset of channels from within a Field Trip data
% structure. Channels are selected by name (matching names in the "label"
% cell array).
%
% "oldftdata" points to a Field Trip data structure to process.
% "chanlist" is a cell array containing desired channel name strings.
%
% "newftdata" is a modified Field Trip data structure containing only the
%   desired channels.
% "chandefs" is an array containing the old channel index corresponding to
%   each new channel.
%
% NOTE - While the indended situation is for "chandefs" to have the same
% number of entries as "chanlist", that will not be the case if some requested
% channels couldn't be found in the trial data.


%
% Look up the channel names.

chancount = 0;
newlabels = {};

for nidx = 1:length(chanlist)

  thisname = chanlist(nidx);
  found = false;

  for cidx = 1:length(oldftdata.label)
    if strcmpi(oldftdata.label{cidx}, thisname)

      found = true;
      chancount = chancount + 1;
      chandefs(chancount) = cidx;
      newlabels{chancount} = thisname;

    end
  end

  if ~found
    disp(sprintf( ...
      '### [wlFT_getChanSubset]  Couldn''t find channel "%s" in FT data.', ...
      thisname ));
  end

end

% Make sure we have a return value.
if ~exist('chandefs', 'var')
  chandefs = [];
end


%
% Build the new Field Trip data structure.

% Fall back to the original structure.
newftdata = oldftdata;

% Proceed if we found at least one of the channels.
if 1 > chancount
  disp(...
'### [wlFT_getChanSubset]  No channels found; returning original structure.');
else

  % Copy the new labels over.
  newftdata.label = newlabels;

  % Reduce and re-save trial data.

  for tidx = 1:length(oldftdata.trial)

    oldtrial = oldftdata.trial{tidx};
    newtrial = [];

    for cidx = 1:chancount
      oldchan = chandefs(cidx);
      newtrial(cidx,:) = oldtrial(oldchan,:);
    end

    newftdata.trial{tidx} = newtrial;

  end

end


%
% Done.

end


%
% This is the end of the file.
