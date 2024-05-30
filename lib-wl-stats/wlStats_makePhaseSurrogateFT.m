function [ newdata trialmap ] = ...
  wlStats_makePhaseSurrogateFT( olddata, replicount )

% function [ newdata trialmap ] = ...
%   wlStats_makePhaseSurrogateFT( olddata, replicount )
%
% This generates a phase-scrambled surrogate of a Field Trip dataset.
%
% "olddata" is a Field Trip dataset to scramble.
% "replicount" is the number of new trials to make from each old trial.
%
% "newdata" is a scrambled Field Trip dataset.
% "trialmap" is a vector mapping new trial indices to old trial indices,
%   such that oldtrial = trialmap(newtrial).


% Initialize.

newdata = olddata;

newtime = {};
newtrial = {};

trialmap = [];

newsampleinfo = [];
newtrialinfo = [];

have_sampleinfo = isfield( olddata, 'sampleinfo' );
have_trialinfo = isfield( olddata, 'trialinfo' );



% Build surrogate trials.

trialcount = length(olddata.time);
chancount = length(olddata.label);

for tidx = 1:trialcount

  thistime = olddata.time{trialcount};
  thistrial = olddata.trial{trialcount};

  if have_sampleinfo
    thissampleinfo = olddata.sampleinfo(tidx,:);
  end

  if have_trialinfo
    thistrialinfo = olddata.trialinfo(tidx,:);
  end

  for ridx = 1:replicount

    thisnewtrial = nan(size(thistrial));

    for cidx = 1:chancount
      thisnewtrial(cidx,:) = ...
        wlStats_makePhaseShuffledWave( thistrial(cidx,:) );
    end


    % Add columns.
    newtime = [ newtime { thistime } ];

    % Add columns.
    newtrial = [ newtrial { thisnewtrial } ];

    if have_sampleinfo
      % Add rows.
      newsampleinfo = [ newsampleinfo ; thissampleinfo ];
    end

    if have_trialinfo
      % Add rows.
      newtrialinfo = [ newtrialinfo ; thistrialinfo ];
    end

  end

end



% Store the revised time and trial information.

newdata.time = newtime;
newdata.trial = newtrial;

if have_sampleinfo
  newdata.sampleinfo = newsampleinfo;
end

if have_trialinfo
  newdata.trialinfo = newtrialinfo;
end


% Done.
end


%
% This is the end of the file.
