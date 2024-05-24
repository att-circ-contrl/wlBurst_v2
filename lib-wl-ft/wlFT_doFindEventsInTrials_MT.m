function eventmatrixdata = wlFT_doFindEventsInTrials_MT( trialftdata, ...
  bandlist, segconfig, paramconfig, bandoverrides, tattleprogress )

% function eventmatrixdata = wlFT_doFindEventsInTrials_MT( trialftdata, ...
%   bandlist, segconfig, paramconfig, bandoverrides, tattleprogress )
%
% This function calls wlProc_doSegmentAndParamExtract() for each trial in
% "trialftdata", and for each band in "bandlist", storing the resulting
% events and auxiliary data in an "event matrix" structure per EVMATRIX.txt.
%
% The "_MT" implementation is multithreaded, using "parfor" to process trials
% from "trialftdata" in parallel. Per Matlab's documentation, this falls back
% to single-threaded operation if called from within another parfor loop.
%
% Bands, trials, and channels are all parallelized.
%
% "trialftdata" is a Field Trip data structure containing trials to process.
% "bandlist" is an array of structures with the following fields:
%   "band" [ min max ] defines a frequency band of interest.
%   "name" is a character array containing a human-readable band name.
%   "label" is a character array containing a filename-safe band ID string.
% "segconfig" specifies the segmentation algorithm to use, per SEGCONFIG.txt.
% "paramconfig" specifies the parameter extraction algorithm to use, per
%   PARAMCONFIG.txt.
% "bandoverrides" is an array of structures containing band-specific
%   override values for "segconfig" and "paramconfig". There are as many
%   array elements as there are bands. Each element is a structure with
%   "seg" and "param" fields, each of which contains a structure that
%   holds field values that should override those specified in "segconfig"
%   and "paramconfig".
% "tattleprogress" is an optional argument. If present and set to "true",
%   progress messages are displayed.
%
% "eventmatrixdata" is a structure describing detected events and auxiliary
%   data, per EVMATRIX.txt.


% FIXME - Magic configuration values.

% Number of lowest-frequency periods to use for window roll-off.
% 6 cycles gives us a 0.5 second roll-off in the beta band.
rolloff_q = 6;


% Get tattle state.

if ~exist('tattleprogress', 'var')
  tattleprogress = false;
end

% FIXME - Diagnostics.
%tattleconfigs = tattleprogress;
tattleconfigs = false;


% Extract the sampling rate.

ftrate = wlFT_getSamplingRate(trialftdata);


% Get the trial start samples (from sampleinfo).
fttrialstarts = wlFT_getTrialStartSamples(trialftdata);


% Initialize the "event matrix" structure.

% NOTE - struct() requires cell arrays to be wrapped by single-cell
% cell arrays. The wrapper cell arrays are interpreted as holding an array
% of initialization values for an array of structs, rather than as an
% initialization value for a single struct. So we initialize the single
% struct as an array of 1 struct.

eventmatrixdata = struct( ...
  'events', {{}}, 'waves', {{}}, 'auxdata', {{}}, ...
  'bandinfo', bandlist, 'samprate', ftrate );


% Initialize indices.

bandcount = length(bandlist);
trialcount = length(trialftdata.trial);
chancount = size(trialftdata.trial{1});
chancount = chancount(1);

indmax = bandcount * trialcount * chancount;


% Banner.

if tattleprogress
  disp('-- Processing trials to find events.');
  disp(sprintf( '.. Iterating %d bands, %d trials, %d channels.', ...
    bandcount, trialcount, chancount ));
  disp(datetime);
end


% Initialize per-band configuration.

for bidx = 1:bandcount

  thisoverseg = bandoverrides(bidx).seg;
  thisoverparam = bandoverrides(bidx).param;

  newconfigseg = segconfig;
  flabels = fieldnames(thisoverseg);
  for fidx = 1:length(flabels)
    newconfigseg = setfield( newconfigseg, flabels{fidx}, ...
      getfield(thisoverseg, flabels{fidx}) );
  end

  newconfigparam = paramconfig;
  flabels = fieldnames(thisoverparam);
  for fidx = 1:length(flabels)
    newconfigparam = setfield( newconfigparam, flabels{fidx}, ...
      getfield(thisoverparam, flabels{fidx}) );
  end

  segconfiglist{bidx} = newconfigseg;
  paramconfiglist{bidx} = newconfigparam;


  if tattleconfigs

    disp(sprintf( '.. %s configs:', bandlist(bidx).name ));

    scratch = 'Seg:';
    flabels = fieldnames(newconfigseg);
    for fidx = 1:length(flabels)
      scratch = [ scratch sprintf('  %s: ', flabels{fidx}) ];
      thisval = getfield(newconfigseg, flabels{fidx});
      if isnumeric(thisval)
        scratch = [ scratch sprintf('%.2f', thisval) ];
      elseif ischar(thisval)
        scratch = [ scratch thisval ];
      else
        scratch = [ scratch '???' ];
      end
    end
    disp(scratch);

    scratch = 'Param:';
    flabels = fieldnames(newconfigparam);
    for fidx = 1:length(flabels)
      scratch = [ scratch sprintf('  %s: ', flabels{fidx}) ];
      thisval = getfield(newconfigparam, flabels{fidx});
      if isnumeric(thisval)
        scratch = [ scratch sprintf('%.2f', thisval) ];
      elseif ischar(thisval)
        scratch = [ scratch thisval ];
      else
        scratch = [ scratch '???' ];
      end
    end
    disp(scratch);

  end

end

if tattleconfigs
  disp('.. End of per-band configs.');
end

% Store per-band configuration in the event matrix.

eventmatrixdata.segconfigbyband = segconfiglist;
eventmatrixdata.paramconfigbyband = paramconfiglist;


%
% First pass: detect events.


% Initialize temporary results variables.
% These have to be "sliceable", and have only one varying index.
% So, they're one-dimensional cell-arrays that we unpack later.

results_events = {};
results_waves = {};
results_aux = {};


% Iterate all axes in parallel.

parfor indidx = 1:indmax


  % Extract actual loop indices.

  [ bidx tidx cidx ] = ind2sub([ bandcount, trialcount, chancount ], indidx);


  % Band-related information.

  thisband = bandlist(bidx).band;

  % Rolloff window size.
  rollsampsdesired = round(rolloff_q * ftrate / min(thisband));


  % Set up this trial.

  timedata = trialftdata.time{tidx};
  sampcount = length(timedata);

  rollsamps = min(rollsampsdesired, round(0.4 * sampcount));
  rollwindow = wlProc_calcCosineWindow( ...
    rollsamps, sampcount - rollsamps, sampcount );


  % Get this channel's sample data for this trial.

  sampdata = trialftdata.trial{tidx}(cidx,:);

  % Zero-average and apply a rolloff window.

  sampdata = sampdata - mean(sampdata);
  sampdata = sampdata .* rollwindow;




  % Do event segmentation and parameter extraction.

  [ events, waves, auxinfo ] = wlProc_doSegmentAndParamExtract( ...
    sampdata, ftrate, thisband, segconfiglist{bidx}, paramconfiglist{bidx} );

  % Augment auxwaves with the original trial waveform and timestamps.
  % NOTE - The waveform does have our roll-off applied.
  waves.ftwave = sampdata;
  waves.fttimes = timedata;


  % Render the events; we need this to get waveform statistics.
  events = wlAux_getReconFromParams(events);


      % Compute and store event statistics.
      % FIXME - Break this out into "event info <-> auxdata" functions.

      trial_bpf_rms = rms(waves.bpfwave);

      for eidx = 1:length(events)

        thisev = events(eidx);

        eventsamps = length(thisev.wave);
        firstsamp = thisev.sampstart + round(thisev.times(1) * ftrate);
        lastsamp = firstsamp + eventsamps - 1;

        % FIXME - Nudge the input sample range if rounding gives an
        % off-by-1 problem.

        if firstsamp < 1
          lastsamp = lastsamp + (1 - firstsamp);
          firstsamp = 1;
        end

        if lastsamp > length(sampdata)
          firstsamp = firstsamp + (length(sampdata) - lastsamp);
          lastsamp = length(sampdata);
        end

        % Event location.

        thisev.auxdata.ft_trialstart = fttrialstarts(tidx);
        thisev.auxdata.ft_sampstart = firstsamp;
        thisev.auxdata.ft_sampend = lastsamp;
        thisev.auxdata.ft_trialnum = tidx;
        thisev.auxdata.ft_channelnum = cidx;
        thisev.auxdata.ft_bandnum = bidx;
        thisev.auxdata.ft_bandmin = min(thisband);
        thisev.auxdata.ft_bandmax = max(thisband);
        thisev.auxdata.ft_eventnum = eidx;

        % Event power statistics.

        thisev.auxdata.ft_trial_bpf_rms = trial_bpf_rms;
        thisev.auxdata.ft_event_rms = rms(thisev.wave);
        thisev.auxdata.ft_event_max = max(abs(thisev.wave));

        if isfield(segconfiglist{bidx}, 'dbpeak')
          thisev.auxdata.ft_detthresh = segconfiglist{bidx}.dbpeak;
        end

        % Region-of-interest information.

        % For now, the "region of interest" is the entire trial.
        % This can be changed via post-processing.
        thisev.auxdata.ft_roistart = 1;
        thisev.auxdata.ft_roistop = sampcount;

        % Parameter fitting.

        thisev.auxdata.ft_f1 = thisev.f1;
        thisev.auxdata.ft_f2 = thisev.f2;
        thisev.auxdata.ft_a1 = thisev.a1;
        thisev.auxdata.ft_a2 = thisev.a2;
        thisev.auxdata.ft_p1 = thisev.p1;
        thisev.auxdata.ft_p2 = thisev.p2;
        thisev.auxdata.ft_rollon = thisev.rollon;
        thisev.auxdata.ft_rolloff = thisev.rolloff;
        thisev.auxdata.ft_duration = thisev.duration;

        events(eidx) = thisev;

      end  % Event iteration.


  % Store results in scratch variables until after parallel processing
  % has finished.

  results_events{indidx} = events;
  results_waves{indidx} = waves;
  results_aux{indidx} = auxinfo;

end  % Band iteration.


% Second pass: save the results.
% We need to unpack the multidimensional arrays.

for indidx = 1:indmax

  % Extract actual loop indices.
  [ bidx tidx cidx ] = ind2sub([ bandcount, trialcount, chancount ], indidx);

  eventmatrixdata.events{bidx, tidx, cidx} = results_events{indidx};
  eventmatrixdata.waves{bidx, tidx, cidx} = results_waves{indidx};
  eventmatrixdata.auxdata{bidx, tidx, cidx} = results_aux{indidx};

end


% Banner.

if tattleprogress
  disp(datetime);
  disp('-- Finished searching for events.');
end



%
% Done.

end


%
% This is the end of the file.
