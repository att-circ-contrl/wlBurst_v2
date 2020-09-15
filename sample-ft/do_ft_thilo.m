% Field Trip-related test scripts - Extracting bursts from FT data.
%
% See LICENSE.md for distribution information.


%
%
% Includes.

do_ft_init



%
%
% Configuration.


% Data reduction, for fast tests.

use_one_band = false;
%one_band_chosen = 1;  % Theta.
%one_band_chosen = 2;  % Alpha.
%one_band_chosen = 3;  % Beta.
one_band_chosen = 4;  % Low gamma.
%one_band_chosen = 5;  % High gamma.


% Plotting decimation and limits.
% NOTE - Decimating trials, not events within a trial.

stride_trial = eventstride;
%stride_trial = 1;

stride_channel = 1;

%bandplots_max = eventplotsperband;
bandplots_max = inf;


% Filtering.

% 60 Hz notch filter for input waveforms.
use_notch = true;
notch_center = 60.0;
notch_halfwidth = 3.0;
notch_order = 20;


% Data.

inputfile = 'thilo-data/LFP_B_tmplate_01.mat';
inputvar = 'DATA';
targetchannels = { 'CSC5LFP' };
outputfile = sprintf('%s/ftthiloevents.mat', datadir);


% Manually specified padding for Thilo's data.
% Startup has detection-stabilization artifacts due to filtering.
% Reward has artifacts due to monkey anticipation motions disturbing probes.
% Frequency detection also gets trains of spurious events near the end.

padtimestart = 0.40;
padtimeend = 0.40;

% This flag sets whether we load Thilo-specific data for reward times.
% The fallback is to do artifact detection instead.

use_thilo_specific = true;


% Region of interest function - fallback version.
% NOTE - Using "deal" to return multiple outputs.

% ROI is the entire trial.
cropfunc = @(thistrial, sampinforow, trialinforow) ...
  deal( 1, (1 + sampinforow(2) - sampinforow(1)) );

% FIXME - Test version, with the ends clipped for debugging.
%cropfunc = @(thistrial, sampinforow, trialinforow) ...
%  deal( 1 + 50, (1 + sampinforow(2) - sampinforow(1)) - 80 );


%
% Segmentation and extraction.

% Set up defaults that are appropriate for the curated FT data.
% These can be overridden by band-specific values.

% NOTE - The "3 sigma" rule of thumb is 9.5 dB.
% If dbpeak is less than dbend, the original detection segments are used
% as-is rather than being extended.


% NOTE - Global values get overridden by band-specific values.

segconfig_mag = struct( 'type', 'magdual', ...
  'qlong', 10, ...
  'qdrop', 1.0, 'qglitch', 1.0, ...
  'dbpeak', 6, 'dbend', 2 );

segconfig_freq = struct( 'type', 'freqdual', ...
  'noiseband', segbandnoise, 'noisesnr', segnoisesnrchosen, ...
  'qlong', 10, 'qshort', 0.25, ...
  'qdrop', 1.0, 'qglitch', 0.5, ...
  'dbpeak', 3, 'dbend', 2 );


paramconfig_coarse = struct( 'type', 'grid', 'gridsteps', 7 );

paramconfig_anneal = struct( 'type', 'annealamp', 'gridsteps', 5, ...
  'matchfreq', matchfreq, 'matchamp', matchamp, ...
  'matchlength', matchlength, 'matcholap', matcholap, ...
  'tunnelmax', annealmaxtries, 'totalmax', annealmaxtotal );

% Two-step annealing with twice the maximum step count.
% This will hopefully converge most of the time.
paramconfig_annealfull = struct( 'type', 'annealboth', 'gridsteps', 5, ...
  'matchfreq', matchfreq, 'matchamp', matchamp, ...
  'matchlength', matchlength, 'matcholap', matcholap, ...
  'tunnelmax', annealmaxtries, 'totalmax', annealmaxtotal * 2 );

% The actual configurations to be used.

%paramconfig_chosen = paramconfig_coarse;
%paramconfig_chosen = paramconfig_anneal;
paramconfig_chosen = paramconfig_annealfull;


% Band-specific parameter values.

dbpeak_mag = [ 6, 7, 6, 5, 4 ];
dbend_mag =  [ 5, 2, 1, 1, 0 ];
%qlong_mag =  [ 10, 10, 10, 10, 30 ];
qlong_mag =  [ inf, 10, 10, 10, inf ];  % Use DC average for theta, gamma_hi
qdrop_mag =  [ 0.25, 0.5, 0.5, 1.0, 3.0 ];

dbpeak_freq = [ 0, 3, 3, 4, 4 ];
dbend_freq =  [ -1, 2, 1, 1, 0 ];
qlong_freq =  [ 10, 10, 10, 10, 30 ];
%qlong_freq =  [ inf, 10, 10, 10, inf ];  % Use DC average for theta, gamma_hi
qshort_freq =  [ 0.25, 0.25, 0.25, 0.5, 1.0 ];
qdrop_freq =  [ 0.5, 0.5, 0.5, 0.5, 1.0 ];

for bidx = 1:length(bandlist)

  bandoverrides_mag(bidx) = struct( 'seg', struct( ...
    'dbpeak', dbpeak_mag(bidx), 'dbend', dbend_mag(bidx), ...
    'qlong', qlong_mag(bidx), 'qdrop', qdrop_mag(bidx) ...
    ), 'param', struct() );

  bandoverrides_freq(bidx) = struct( 'seg', struct( ...
    'dbpeak', dbpeak_freq(bidx), 'dbend', dbend_freq(bidx), ...
    'qlong', qlong_freq(bidx), 'qshort', qshort_freq(bidx), ...
    'qdrop', qdrop_freq(bidx) ...
    ), 'param', struct() );

end


%
%
% Banner.

disp('== Loading Field Trip data.');


%
% Load the datafile.

isok = true;

load(inputfile, inputvar);

% Rename this to something consistent and sensible.
% NOTE - This _should_ be smart enough to copy-on-modify only, but we should
% make sure we have enough headroom for duplication just in case.
rawdata = eval(inputvar);


% Make sure we have a valid sampling rate.

ftrate = wlFT_getSamplingRate(rawdata);

if isnan(ftrate)
  isok = false;
  disp('### Couldn''t get sampling rate.');
% FIXME - Debugging.
else
  disp(sprintf('Sampling rate:  %d', round(ftrate)));
end


% FIXME - Load Thilo-specific information.

if isok && use_thilo_specific

  load(inputfile, 'tinfo');

  thilo_rewardsamps = [];

  scratch = tinfo.rewOnTimes;

  for tidx = 1:length(scratch);
    % Convert a negative timestamp in seconds into a positive sample offset.
    thilo_rewardsamps(tidx) = round( - ftrate * scratch{tidx}(1) );
  end

  clear scratch;


  % Add the stop time as an extra field in "trialinfo".

  auxidx = size(rawdata.trialinfo);
  auxidx = auxidx(2) + 1;

  rawdata.trialinfo(:,auxidx) = thilo_rewardsamps;


  % Make a crop function that checks this new endpoint.

  cropfunc = @(thistrial, sampinforow, trialinforow) ...
    deal( 1, trialinforow(auxidx) );

end


% FIXME - Not doing automatic artifact identification yet.
% We do need it; about 10% of trials are bad.



disp('-- Field Trip data loaded.');


%
% Detect events in the FT data, and make plots.

if isok

  disp(sprintf( '.. %d trials in dataset.', length(rawdata.trial) ));


  % Extract our desired channels.

  [ rawdata chandefs ] = wlFT_getChanSubset(rawdata, targetchannels);

  if 1 > length(chandefs)
    isok = false;
    disp('### Couldn''t identify target channels.');
  end

end

if isok

  % Preprocessing step: Trim the trials.

  [ trimmeddata cropdefs ] = wlFT_trimTrials(rawdata, cropfunc);


  % Preprocessing step: Apply a notch filter to remove power line noise.
  % This shows up in a fraction of the trials.
  % Do this _after_ we've trimmed the electrical artifacts, to avoid large
  % excursions. We may still get edge effects.
  % NOTE - We're using "filtfilt", which gives no phase shift but twice the
  % filter order.

  if use_notch

    disp('-- Applying notch filter.');

    powerfilt = designfilt( 'bandstopiir', 'SampleRate', ftrate, ...
      'HalfPowerFrequency1', notch_center - notch_halfwidth, ...
      'HalfPowerFrequency2', notch_center + notch_halfwidth, ...
      'FilterOrder', notch_order );

    for tidx = 1:length(trimmeddata.trial)

      thistrial = trimmeddata.trial{tidx};

      [ chancount, sampcount ] = size(thistrial);

      for cidx = 1:chancount
        thischannel = thistrial(cidx, :);
        thischannel = filtfilt(powerfilt, thischannel);
        thistrial(cidx, :) = thischannel;
      end

      trimmeddata.trial{tidx} = thistrial;

    end

    disp('-- Finished applying notch filter.');

  end


  % FIXME - Clip the band list for testing.
  if use_one_band
    bandlist = bandlist(one_band_chosen:one_band_chosen);
    bandoverrides_mag = bandoverrides_mag(one_band_chosen:one_band_chosen);
    bandoverrides_freq = bandoverrides_freq(one_band_chosen:one_band_chosen);
  end


  %
  %
  % Do event detection.

  disp('== Detecting using magnitude.');


  newmatrix_mag = wlFT_doFindEventsInTrials_MT(trimmeddata, bandlist, ...
    segconfig_mag, paramconfig_chosen, bandoverrides_mag, true );
  newmatrix_mag = wlFT_pruneEventsByTime(newmatrix_mag, ...
    padtimestart, padtimeend);

  newdata_mag = wlFT_getEventTrialsFromMatrix(newmatrix_mag);


  disp('== Detecting using frequency stability.');


  newmatrix_freq = wlFT_doFindEventsInTrials_MT(trimmeddata, bandlist, ...
    segconfig_freq, paramconfig_chosen, bandoverrides_freq, true );
  newmatrix_freq = wlFT_pruneEventsByTime(newmatrix_freq, ...
    padtimestart, padtimeend);

  newdata_freq = wlFT_getEventTrialsFromMatrix(newmatrix_freq);


  disp('== Finished detecting.');


  %
  %
  % Do plotting.

  disp('-- Plotting detected events.');
  disp(datetime);


  % Plot by matrix.

  wlPlot_plotAllMatrixEvents(figconfig, newmatrix_mag, ...
    'Mag Recon', 'mag', bandplots_max, stride_trial, stride_channel);
  wlPlot_plotAllMatrixEvents(figconfig, newmatrix_freq, ...
    'Freq Recon', 'freq', bandplots_max, stride_trial, stride_channel);


  disp(datetime);
  disp('-- Finished plotting events.');


  %
  %
  % Collect and report event statistics.


  [ bandcount trialcount chancount ] = size(newmatrix_mag.events);

  for bidx = 1:bandcount

    thiscountmag = 0;
    thiscountfreq = 0;

    for tidx = 1:trialcount
      for cidx = 1:chancount

        evlistmag = newmatrix_mag.events{bidx, tidx, cidx};
        evlistfreq = newmatrix_freq.events{bidx, tidx, cidx};

        thiscountmag = thiscountmag + length(evlistmag);
        thiscountfreq = thiscountfreq + length(evlistfreq);
      end
    end

    disp(sprintf( '%s band:   (Mag)  %d events  (%.1f per trial)', ...
      bandlist(bidx).name, ...
      thiscountmag, thiscountmag / (trialcount * chancount) ));
    disp(sprintf( '%s band:   (Freq) %d events  (%.1f per trial)', ...
      bandlist(bidx).name, ...
      thiscountfreq, thiscountfreq / (trialcount * chancount) ));
  end


  %
  %
  % Save detected events.

  disp('-- Saving events to disk.');

% FIXME - Make a copy of the trimmed-coordinate events, for debugging.
% This also includes channel pruning.
trimmed_mag = newdata_mag;
trimmed_freq = newdata_freq;

  % Align sample indices back to un-trimmed data.
  newdata_mag = wlFT_unTrimMetadata(newdata_mag, cropdefs);
  newdata_freq = wlFT_unTrimMetadata(newdata_freq, cropdefs);

  % Map channels back to the original channel indices.
  newdata_mag = wlFT_unMapChannels(newdata_mag, chandefs);
  newdata_freq = wlFT_unMapChannels(newdata_freq, chandefs);

  save( outputfile, ...
    'newmatrix_mag', 'newmatrix_freq', ...
    'cropdefs', 'chandefs', ...
    'newdata_mag', 'newdata_freq' );

  disp('-- Finished saving events.');

end  % "isok" check.


%
%
% Banner.

disp('== Finished detecting events in Field Trip data.');



%
% This is the end of the file.
