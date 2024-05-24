function artifactstruct = wlFT_getEventsAsArtifacts( ...
  eventmatrixdata, ftlabels, bandwanted )

% function artifactstruct = wlFT_getEventsAsArtifacts( ...
%   eventmatrixdata, ftlabels, bandwanted )
%
% This function converts an "event matrix" structure as described by
% EVMATRIX.txt into an artifact definition structure per ft_artifact_XXX.
% Nx2 matrix of the type returned by ft_artifact_XXX.
%
% This is intended to be used with ft_databrowser to visualize bursts in
% trials as if they were artifacts.
%
% "eventmatrixdata" is a structure describing detected events and auxiliary
%   data, per EVMATRIX.txt.
% "ftlabels" is a copy of the "label" field of the Field Trip dataset.
%   This maps event channel indices to FT labels.
% "bandwanted" specifies the band to use (first index into events{}). If this
%   is omitted or NaN, all bands are used.
%
% "artifactstruct" is a structure with the following fields, intended to be
%   stored in cfg.artfctdef.wlburst:
%   "artifact" is a Nx2 matrix containing the locations of detected
%     events in the original data, in a format similar to "trl" from
%     ft_definetrial (per ft_artifact_XXX).
%   "channel" is a Nx1 cell array with channel labels for each detected event.


startendtable = zeros(0,2);
chantable = {};

if ~exist('bandwanted', 'var')
  bandwanted = NaN;
end


events = eventmatrixdata.events;

bandcount = size(events,1);
trialcount = size(events,2);
chancount = size(events,3);


for bidx = 1:bandcount
  if (~isnan(bandwanted)) && (bidx ~= bandwanted)
    continue;
  end

  for tidx = 1:trialcount
    for cidx = 1:chancount

      thisevlist = events{bidx,tidx,cidx};

      for eidx = 1:length(thisevlist)
        thisev = thisevlist(eidx);

        sampstart = thisev.sampstart + thisev.auxdata.ft_trialstart;
        sampend = sampstart + (thisev.s2 - thisev.s1);

        startendtable = [ startendtable ; sampstart, sampend ];
        chantable = [ chantable ; ftlabels(cidx) ];
      end

    end
  end
end


% Sort these in ascending order of start time.
% NOTE - None of my routines care about that, and it looks like FT doesn't
% either, but doing it anyways.

scratch = startendtable(:,1);
[ scratch sortidx ] = sort(scratch);

startendtable = startendtable(sortidx,:);
chantable = chantable(sortidx);


% Build the output structure.

artifactstruct = struct();
artifactstruct.artifact = startendtable;
artifactstruct.channel = chantable;


%
% Done.

end


%
% This is the end of the file.
