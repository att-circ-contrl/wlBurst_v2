function newftevdata = wlFT_unMapChannels(subsetftevdata, chandefs)

% function newftevdata = wlFT_unMapChannels(subsetftevdata, chandefs)
%
% This function alters "ft_channelnum" fields in "trialinfo" metadata for
% events extracted from trial data with channel subsets (processed with
% wlFT_getChanSubset()) to use channel indices from the original trial data.
%
% "subsetftevdata" points to a Field Trip data structure to process. This
%   structure should contain event data and "wlnotes" metadata.
% "chandefs" is an array containing the original channel index corresponding
%   to each remapped channel index.
%
% "newftevdata" is a modified Field Trip data structure containing event
%   data and metadata with modified "ft_channelnum" indices.


% Initialize.

newftevdata = subsetftevdata;


% Get indices of the metadata fields we want to modify.
% This is just "ft_channelnum".

field_channelnum = nan;

labels = subsetftevdata.wlnotes.trialinfo_label;
for fidx = 1:length(labels)

  thislabel = labels{fidx};

  if strcmp(thislabel, 'channelnum')
    field_channelnum = fidx;
  end

end


% Walk through the event metadata, remapping appropriately.

if isnan(field_channelnum)
  disp( ...
'### [wlFT_unMapChannels]  Couldn''t find "channel number" metadata field!' );
else

  for evidx = 1:length(newftevdata)

    mappedchan = newftevdata.trialinfo(evidx, field_channelnum);

    if mappedchan > length(chandefs)
      disp(sprintf( ...
        '### [wlFT_unMapChannels]  Mapped channel %d is not in table!.', ...
        mappedchan ))
    else
      newftevdata.trialinfo(evidx, field_channelnum) = chandefs(mappedchan);
    end

  end

end


%
% Done.

end


%
% This is the end of the file.
