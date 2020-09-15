function [ ftdata, evmatrix ] = wlSynth_genFieldTrip( ...
  samprate, chancount, trialcount, trialdur, burstdefs, ...
  channelratevar, channelnoisevar )

% function [ ftdata, evmatrix ] = wlSynth_genFieldTrip( ...
%   samprate, chancount, trialcount, trialdur, burstdefs, ...
%   channelratevar, channelnoisevar )
%
% This function generates a minimal Field Trip dataset with synthetic
% oscillatory burst events. An "event matrix" containing ground truth
% information for oscillations is also returned.
%
% "samprate" is the number of samples per second.
% "chancount" is the number of channels to generate.
% "trialcount" is the number of trials to generate.
% "trialdur" [ min max ] specifies minimum and maximum trial durations, in
%   seconds.
% "burstdefs" is an array of burst type definition structures, with fields
%   as defined in BURSTTYPEDEF.txt.
% "channelratevar" [ min max ] specifies the minimum and maximum factor by
%   which burst rates in a channel are to be scaled. Each channel gets its
%   own scale factor (picked uniformly in the log domain).
% "channelnoisevar" [ min max ] specifies the minimum and maximum values to
%   add to signal to noise ratios in a channel, in dB. Each channel gets its
%   own SNR offset (picked uniformly).
%
% "ftdata" is a Field Trip data structure containing trial records with
%   synthetic oscillatory bursts. Trial timestamps abut each other (the
%   trials can be concatenated to get a valid signal waveform with no
%   discontinuities).
% "evmatrix" is a data structure containing ground-truth information about
%   oscillatory burst events in the trials, using the format described in
%   EVMATRIX.txt. A single frequency band is defined.
%   NOTE - Events may be recorded multiple times if they span multiple trials.


% Figure out our trial sizes, and the entire waveform size.

for tidx = 1:trialcount
  trialsamps(tidx) = min(trialdur) + rand * ( max(trialdur) - min(trialdur) );
  trialsamps(tidx) = max( 1, round(samprate * trialsamps(tidx)) );
end

wavesamps = sum(trialsamps);


% Further configuration.

% Our noise/BPF band isn't quite the full Nyquist range, just close.
% NOTE - Matlab's filters go dodgy at low frequencies, so this may get
% peculiar at the low end.

bandwide = [ 1 round(0.4 * samprate) ];


%
% Build channel waveforms.

for cidx = 1:chancount

  % Background noise.
  % NOTE - Matlab is giving us BPF artifacts, so generate a wider trace
  % and then trim it.

  padsamps = round(30 * samprate / bandwide(1));

  thischan = [];
  thischan( 1:(wavesamps + padsamps + padsamps) ) = 0;

  thischan = wlSynth_traceAddNoise( thischan, samprate, 'pink', ...
    bandwide(1), bandwide(2), 1, bandwide(1), bandwide(2) );

  thischan = thischan( (1 + padsamps):(wavesamps + padsamps) );

  % FIXME - Adjust absolute noise amplitude by a small random amount.
  gainfact = log(0.5) + rand * (log(2) - log(0.5));
  gainfact = exp(gainfact);
  thischan = thischan * gainfact;


  % Build a perturbed burst definition list for this channel.

  thisratefact = log(min(channelratevar)) ...
    + rand * ( log(max(channelratevar)) - log(min(channelratevar)) );
  thisratefact = exp(thisratefact);

  thisnoiseofs = min(channelnoisevar) ...
    + rand * ( max(channelnoisevar) - min(channelnoisevar) );

  thisdeflist = burstdefs;

  for didx = 1:length(burstdefs)
    thisdeflist(didx).rate = thisdeflist(didx).rate * thisratefact;
    thisdeflist(didx).snrrange = thisdeflist(didx).snrrange + thisnoiseofs;
  end


  % Add bursts to the background.

  [ thischan, thisevdata ] = wlSynth_traceAddBursts( ...
    thischan, samprate, thisdeflist );

  channeldata(cidx,:) = thischan;
  truthdata{cidx} = thisevdata;

end


%
% Parcel this into Field Trip trials, and fill in the rest of the FT data.


for cidx = 1:chancount
  chanlabels{cidx} = sprintf('Channel_%04d', cidx);
end

timeseries = 1:wavesamps;
timeseries = (timeseries - 1) / samprate;

thispos = 1;
for tidx = 1:trialcount
  ftsampinfo(tidx,1) = thispos;
  thispos = thispos + trialsamps(tidx);
  ftsampinfo(tidx,2) = thispos - 1;
end

for tidx = 1:trialcount
  samprange = ftsampinfo(tidx,:);

  fttimes{tidx} = timeseries(samprange(1):samprange(2));

  fttrials{tidx} = channeldata(:,samprange(1):samprange(2));
end


% Remember that cell arrays passed to struct() are assumed to be initializing
% an _array_ of structures. Wrap in {} to get a single structure out.

ftdata = struct( 'trial', {fttrials}, 'time', {fttimes}, ...
  'label', {chanlabels}, 'fsample', samprate, 'sampleinfo', ftsampinfo );


%
% Fill in trial wave data and initialize auxiliary data.

for bidx = 1:1
  for cidx = 1:chancount
    for tidx = 1:trialcount

      evwaves{bidx, tidx, cidx} = struct( ...
        'ftwave', fttrials{tidx}(cidx,:), ...
        'fttimes', fttimes{tidx} );

      evaux{bidx,tidx,cidx} = struct();

    end
  end
end


%
% Sort events by trial and fill in the event matrix.

for bidx = 1:1
  for cidx = 1:chancount

    thisevlist = truthdata{cidx};

    for tidx = 1:trialcount
      % Empty array with the correct fields.
      evlists{bidx, tidx, cidx} = thisevlist(1:0);
    end

    for eidx = 1:length(thisevlist)

      for tidx = 1:trialcount

        % NOTE - Events that straddle a trial boundary get assigned to both
        % trials (duplicate event records).

        % Get a new copy of this event record.
        thisev = thisevlist(eidx);

        % Get sample ranges.

        trialrange = ftsampinfo(tidx,:);

        sampfirst = thisev.sampstart - round(samprate * 0.5 * thisev.rollon);
        samplast = thisev.sampstart ...
          + round( samprate * (thisev.duration + 0.5 * thisev.rolloff) );

        % Add the event to the trial, if appropriate.

        if (sampfirst <= max(trialrange)) && (samplast >= min(trialrange))

          % Convert position to be relative to the start of the trial.
          thisev.sampstart = thisev.sampstart - min(trialrange);

          % Store this event record.
          thispos = 1 + length(evlists{bidx, tidx, cidx});
          evlists{bidx, tidx, cidx}(thispos) = thisev;

        end
      end

    end

  end
end


% Remember that cell arrays passed to struct() are assumed to be initializing
% an _array_ of structures. Wrap in {} to get a single structure out.

evmatrix = struct( ...
  'events', {evlists}, 'waves', {evwaves}, 'auxdata', {evaux}, ...
  'bandinfo', ...
  [ struct( 'band', bandwide, 'name', 'Wide', 'label', 'wb' ) ], ...
  'samprate', samprate, ...
  'segconfigbyband', [ struct('type', 'groundtruth') ], ...
  'paramconfigbyband', [ struct('type', 'groundtruth') ] );


%
% Done.

end


%
% This is the end of the file.
