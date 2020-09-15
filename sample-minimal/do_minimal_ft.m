% Minimal tutorial script - Extracting burst events from FT data.
% See LICENSE.md for distribution information.

%
%
% Configuration.

%
% Paths.

addpath('lib-wl-synth', 'lib-wl-proc', 'lib-wl-ft', 'lib-wl-aux', ...
  'lib-wl-plot');


%
% Data files.

inputfile = 'thilo-data/LFP_B_tmplate_01.mat';
outputfile = 'output/minimal-ftevents.mat';
plotdir = 'output';


%
% Bands of interest.

% NOTE - Splitting gamma, as detection works best if bands are about one
% octave wide.
bandlist = [ ...
  struct('band', [ 4 7.5 ],    'label', 'th', 'name', 'Theta') ...
  struct('band', [ 7.5 12.5 ], 'label', 'al', 'name', 'Alpha') ...
  struct('band', [ 12.5, 30 ], 'label', 'be', 'name', 'Beta') ...
  struct('band', [ 30 60 ],    'label', 'gl', 'name', 'Gamma (low)') ...
  struct('band', [ 60 100 ],   'label', 'gh', 'name', 'Gamma (high)') ];


%
% Segmentation and parameter extraction.

% NOTE - The "3 sigma" rule of thumb is 9.5 dB.
% For this data, we need to be a bit more sensitive than that.


% Detection by magnitude thresholding.

segconfig = struct( 'type', 'magdual', ...
  'qlong', 10, 'qdrop', 1.0, 'qglitch', 1.0, ...
  'dbpeak', 6, 'dbend', 2 );

% Envelope fitting by a coarse grid search.

paramconfig = struct( 'type', 'grid', 'gridsteps', 7 );


% Band-specific detection tuning.

seg_dbpeak = [ 6, 7, 6, 5, 4 ];
seg_dbend =  [ 5, 2, 1, 1, 0 ];
seg_qlong =  [ inf, 10, 10, 10, inf ];  % Use DC average for theta, gamma_hi
seg_qdrop =  [ 0.25, 0.5, 0.5, 1.0, 3.0 ];

for bidx = 1:length(bandlist)

  bandoverrides(bidx) = struct( 'seg', struct( ...
    'dbpeak', seg_dbpeak(bidx), 'dbend', seg_dbend(bidx), ...
    'qlong', seg_qlong(bidx), 'qdrop', seg_qdrop(bidx) ...
    ), 'param', struct() );

end



%
%
% Load the FT data.


load(inputfile, 'DATA');

% Get the sampling rate.
ftrate = wlFT_getSamplingRate(DATA);

% Extract our desired channels. Just one, for this dataset.
[ rawdata chandefs ] = wlFT_getChanSubset( DATA, { 'CSC5LFP' } );



%
%
% Preprocessing: Trim the trials.
% We have large electrical artifacts near reward time.


load(inputfile, 'tinfo');


% We're given a negative timestamp in seconds.
% Convert this into a positive sample offset.

thilo_rewardsamps = [];
scratch = tinfo.rewOnTimes;

for tidx = 1:length(scratch);
  thilo_rewardsamps(tidx) = round( - ftrate * scratch{tidx}(1) );
end


% Add the stop time as an extra field in "trialinfo".

auxidx = size(rawdata.trialinfo);
auxidx = auxidx(2) + 1;

rawdata.trialinfo(:,auxidx) = thilo_rewardsamps;


% Make a crop function that checks this new endpoint.

cropfunc = @(thistrial, sampinforow, trialinforow) ...
  deal( 1, trialinforow(auxidx) );

% Crop the trials.
[ trimmeddata cropdefs ] = wlFT_trimTrials(rawdata, cropfunc);



%
%
% Preprocessing: Apply a notch filter.


powerfilt = designfilt( 'bandstopiir', 'SampleRate', ftrate, ...
 'HalfPowerFrequency1', 57.0, 'HalfPowerFrequency2', 63.0, ...
 'FilterOrder', 20 );

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



%
%
% Detect events in the FT data.


eventmatrix = wlFT_doFindEventsInTrials_MT( trimmeddata, bandlist, ...
  segconfig, paramconfig, bandoverrides, true );

% Clip events near the ends of the trial; roll-on and roll-off give
% spurious detections.

padtime = 0.4;
eventmatrix = wlFT_pruneEventsByTime(eventmatrix, padtime, padtime);

% Package events in Field Trip format, to use with FT's visualizers.
events_ft = wlFT_getEventTrialsFromMatrix(eventmatrix);



%
%
% Plot detected events.

figconfig = struct( ...
  'fig', figure, 'outdir', plotdir, ...
  'fsamp', ftrate, ...
  'psfres', 5, 'psolap', 99, 'psleak', 0.75, 'psylim', 50 );

plots_per_band = inf;
trial_stride = 25;
channel_stride = 1;

wlPlot_plotAllMatrixEvents(figconfig, eventmatrix, ...
  'Mag Thresholding', 'mag', plots_per_band, trial_stride, channel_stride);



%
%
% Save detected events.


% Align FT sample indices back to un-trimmed data.
events_ft = wlFT_unTrimMetadata(events_ft, cropdefs);

% Map FT channels back to the original channel indices.
events_ft = wlFT_unMapChannels(events_ft, chandefs);

save( outputfile, 'eventmatrix', 'cropdefs', 'chandefs', 'events_ft' );



%
% This is the end of the file.
