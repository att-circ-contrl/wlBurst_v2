function newftevdata = wlFT_unTrimMetadata(trimmedftevdata, cropdefs)

% function newftevdata = wlFT_unTrimMetadata(trimmedftevdata, cropdefs)
%
% This function alters "sampleinfo" and "trialinfo" metadata for events
% extracted from trimmed trial data to use sample indices from the original
% un-trimmed trial data.
%
% "trimmedftevdata" points to a Field Trip data structure to process. This
%   structure should contain event data and "wlnotes" metadata.
% "cropdefs" is an Nx2 array containing each original trial's cropping limits.
%
% "newftevdata" is a modified Field Trip data structure containing event
%   data and metadata with modified sample indices.


% Initialize.

newftevdata = trimmedftevdata;


% Get indices of metadata fields we want to modify.
% Also get the "trial number" field. That's guaranteed to exist.

field_sampstart = nan;
field_sampend = nan;
field_roistart = nan;
field_roistop = nan;

field_trialnum = nan;

labels = trimmedftevdata.wlnotes.trialinfo_label;
for fidx = 1:length(labels)

  thislabel = labels{fidx};

  if strcmp(thislabel, 'sampstart')
    field_sampstart = fidx;
  elseif strcmp(thislabel, 'sampend')
    field_sampend = fidx;
  elseif strcmp(thislabel, 'roistart')
    field_roistart = fidx;
  elseif strcmp(thislabel, 'roistop')
    field_roistop = fidx;
  elseif strcmp(thislabel, 'trialnum')
    field_trialnum = fidx;
  end

end


% FIXME - Diagnostics.
if isnan(field_sampstart) || isnan(field_sampend) ...
  || isnan(field_roistart) || isnan(field_roistop) ...
  || isnan(field_trialnum)

  disp(sprintf( "--FIDs:   samp: %d - %d   roi: %d - %d   tidx: %d", ...
    field_sampstart, field_sampend, field_roistart, field_roistop, ...
    field_trialnum ));
end


% Walk through the event metadata, shifting appropriately.

if isnan(field_trialnum)
  disp( ...
'### [wlFT_unTrimMetadata]  Couldn''t find "trial number" metadata field!' );
else

  for evidx=1:length(newftevdata.trial)

    tidx = newftevdata.trialinfo(evidx, field_trialnum);

    cropstart = cropdefs(tidx,1);
    cropend = cropdefs(tidx,2);


    % All we have to do is shift things by (cropstart - 1).

    newftevdata.sampleinfo(evidx,:) = newftevdata.sampleinfo(evidx,:) ...
      + cropstart - 1;

    if ~isnan(field_sampstart)
      newftevdata.trialinfo(evidx, field_sampstart) = ...
        newftevdata.trialinfo(evidx, field_sampstart) + cropstart - 1;
    end

    if ~isnan(field_sampend)
      newftevdata.trialinfo(evidx, field_sampend) = ...
        newftevdata.trialinfo(evidx, field_sampend) + cropstart - 1;
    end

    if ~isnan(field_roistart)
      newftevdata.trialinfo(evidx, field_roistart) = ...
        newftevdata.trialinfo(evidx, field_roistart) + cropstart - 1;
    end

    if ~isnan(field_roistop)
      newftevdata.trialinfo(evidx, field_roistop) = ...
        newftevdata.trialinfo(evidx, field_roistop) + cropstart - 1;
    end

  end

end


%
% Done.

end


%
% This is the end of the file.
