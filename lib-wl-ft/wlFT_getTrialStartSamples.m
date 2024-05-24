function trialstarts = wlFT_getTrialStartSamples( ftdata )

% function trialstarts = wlFT_getTrialStartSamples( ftdata )
%
% This extracts the continuous-data sample indices of the first samples of
% each trial in a Field Trip dataset.
%
% This is the first column in ftdata.sampleinfo or ftdata.trialdef or
% cfg.trl.
%
% "ftdata" is a ft_datatype_raw structure to process.
%
% "trialstarts" is a 1xNtrials vector with trial start sample indices.


trialstarts = [];

if isfield(ftdata, 'sampleinfo')

  % New FT way.
  trialstarts = ftdata.sampleinfo(:,1);

elseif isfield(ftdata, 'trialdef')

  % Old FT way.
  trialstarts = ftdata.trialdef(:,1);

elseif isfield(ftdata, 'cfg')
  if isfield(ftdata.cfg, 'trl')

    % Pull information out of the trial definitions passed as config.
    trialstarts = ftdata.cfg.trl(:,1);

  end
end


% If we still have nothing, make up trial start indices.

if isempty(trialstarts)
  disp('###  No sampleinfo, trialdef, or cfg.trl found; guessing instead.');

  prevend = 0;

  trialcount = length(ftdata.time);
  for tidx = 1:trialcount

    thislength = length(ftdata.time{tidx});
    trialstarts = [ trialstarts (prevend + 1) ];
    prevend = prevend + thislength;

  end
end


% Force this to be a 1xN vector.
trialstarts = reshape(trialstarts, 1, []);


%
% Done.

end


%
% This is the end of the file.
