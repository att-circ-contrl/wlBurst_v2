% Minimal tutorial script - Comparing ground truth and detected burst events
% with synthetic data.
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

outputfile = 'output/minimal-synthevents.mat';
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

% Detection by magnitude thresholding.

segconfig = struct( 'type', 'magdual', ...
  'qlong', 10, 'qdrop', 0.5, 'qglitch', 1.0, ...
  'dbpeak', 10, 'dbend', 2 );

% Envelope fitting by a coarse grid search.

paramconfig = struct( 'type', 'grid', 'gridsteps', 7 );


% Brute force threshold sweep range.
detsweepthresholds = 4:1:16;

% Per-band fine-tuned thresholds.
tunedthresholds = [ 8, 12, 12, 8, 9 ];


% The only override we have is DC averaging for theta.

for bidx = 1:length(bandlist)
  bandoverrides(bidx) = struct( 'seg', struct(), 'param', struct() );
end
bandoverrides(1).seg.qlong = inf;



%
%
% Data generation.


% Burst types.
% Min/max duration (periods), frequency ramping, amplitude ramping.
bpeep =  struct( 't', [1 2], 'f', [1   1  ], 'a', [1   1  ] );
bchirp = struct( 't', [2 4], 'f', [0.7 1.5], 'a', [0.3 3  ] );
btone =  struct( 't', [3 6], 'f', [0.8 1.2], 'a', [0.7 1.3] );

% Event generation specification.
% Each record has a band, a rate, and a burst definition.

% Theta band: peeps, 0.5/sec.
% Alpha band: tones (0.2/sec) and chirps, (0.4/sec).
% Beta band: chirps, 1/sec.
% Gamma band: tones, 2/sec.

% This is an array of structs; Matlab's syntax for building this is peculiar.

burstdefs = struct ( 'snrrange', [ -10 20 ], ...
  'rate',      { 0.5,     0.2,        0.4,        1,         2 }, ...
  'noiseband', { [4 7.5], [7.5 12.5], [7.5 12.5], [12.5 30], [30 100 ] }, ...
  'fctrrange', { [4 7.5], [7.5 12.5], [7.5 12.5], [12.5 30], [30 100 ] }, ...
  'durrange',  { bpeep.t, btone.t,    bchirp.t,   bchirp.t,  btone.t }, ...
  'framprange',{ bpeep.f, btone.f,    bchirp.f,   bchirp.f,  btone.f }, ...
  'aramprange',{ bpeep.a, btone.a,    bchirp.a,   bchirp.a,  btone.a } );


%
% Do the generation.

fsamp = 1000;

chancount = 6;
trialcount = 10;

% Trial duration is a range.
trialdur = [ 10 20 ];

% Variation range for event rates and SNR across channels.
channelratevar = [ 0.1 1.0 ];
channelnoisevar = [ -10 10 ];



disp('-- Generating synthetic data.');


% Generate the data traces and lumped ground truth.
[ synthdata synthgt_lumped ] = wlSynth_genFieldTrip( ...
  fsamp, chancount, trialcount, trialdur, ...
  burstdefs, channelratevar, channelnoisevar);

% Generate per-band ground truth.
synthgt_byband = wlAux_splitEvMatrixByBand(synthgt_lumped, bandlist);



%
%
% Perform a brute-force sweep of detection threshold.


% Wave error function, for pruning.
% This calculates the relative RMS error between the reconstructed event and
% the band-pass-filtered input waveform.

waveerrfunc = @(thisev, thiswave) ...
  wlProc_calcWaveErrorRelative( thiswave.bpfwave, thisev.sampstart, ...
    thisev.wave, thisev.s1 );

% Event filtering function, for pruning.
% This rejects anything with 'errbpf' above 0.7.
prunepassfunc = @(thisev) (0.7 >= thisev.auxdata.errbpf);


%
% Perform the detection sweep.

disp('-- Performing brute-force detection threshold sweep.');


clear synthdetect;

for thidx = 1:length(detsweepthresholds)

  % Make a copy of "band overrides", and set the desired threshold.

  bandoverrides_test = bandoverrides;
  for bidx = 1:length(bandlist)
    bandoverrides_test(bidx).seg.dbpeak = detsweepthresholds(thidx);
  end


  % Detect events, and trim events at the ends to avoid rolloff artifacts.

  detect_temp = wlFT_doFindEventsInTrials_MT( synthdata, bandlist, ...
    segconfig, paramconfig, bandoverrides_test, true );

  padtime = 0.5;
  detect_temp = wlFT_pruneEventsByTime(detect_temp, padtime, padtime);


  % Calculate reconstruction error and prune anything that's too large.

  detect_temp = wlFT_calcEventErrors( detect_temp, waveerrfunc, 'errbpf' );
  detect_temp = wlAux_pruneMatrix( detect_temp, prunepassfunc );


  % Store this result in our detection list.

  synthdetect{thidx} = detect_temp;

end


%
% Build an event matrix using the selected threshold from each band.

synthdetect_selected = synthdetect{1};

for bidx = 1:length(bandlist)

  threshdb = tunedthresholds(bidx);

  % Get the threshold sweep array index corresponding to this threshold.

  thcompare = abs(detsweepthresholds - threshdb) < 0.49;
  thidxlist = 1:length(detsweepthresholds);
  thidx = thidxlist(thcompare);


  % Copy the relevant slices from the full detection list.
  % Remember to use parentheses rather than curly braces for slices; we're
  % not dereferencing.

  synthdetect_selected.events(bidx,:,:) = ...
    synthdetect{thidx}.events(bidx,:,:);
  synthdetect_selected.waves(bidx,:,:) = ...
    synthdetect{thidx}.waves(bidx,:,:);
  synthdetect_selected.auxdata(bidx,:,:) = ...
    synthdetect{thidx}.auxdata(bidx,:,:);

  synthdetect_selected.segconfigbyband{bidx} = ...
    synthdetect{thidx}.segconfigbyband{bidx};
  synthdetect_selected.paramconfigbyband{bidx} = ...
    synthdetect{thidx}.paramconfigbyband{bidx};

end



%
%
% Save the synthetic data and raw detection results to disk.

disp('-- Saving synthetic data, ground truth, and detected events.');

% FIXME - This doesn't save "synthdetect", due to size issues.
% This is for good reason - it's 5 GB (due to waveform copies).

save( outputfile, 'synthdata', 'synthgt_lumped', 'synthgt_byband', ...
  'detsweepthresholds', 'synthdetect', ...
  'tunedthresholds', 'synthdetect_selected' );



%
%
% Calculate confusion matrix statistics.


disp('-- Calculating event statistics.');


% Event comparison function; this determines whether two event records
% "match" (refer to the same event).

matchfreq = 1.5;    % Worst-case frequency ratio.
matchamp = 3.0;     % Worst-case amplitude ratio.
matchlength = 4.0;  % Worst-case length ratio.
matcholap = 0.75;   % Worst-case fraction of the smaller event that's covered.

evcomparefunc = @(evfirst, evsecond) ...
  wlProc_calcMatchFromParams( evfirst, evsecond, ...
    matchfreq, matchamp, matchlength, matcholap );


% Compare against ground truth, and record the resulting statistics.
% Don't save this to disk; it's fast to compute, and huge.

clear confstats;

for thidx = 1:length(detsweepthresholds)

  [ fpmat fnmat tpmat matchtruth matchtest missingtruth missingtest ] = ...
    wlFT_compareMatrixEventsVsTruth( ...
      synthgt_byband, synthdetect{thidx}, evcomparefunc );

  confstats{thidx} = struct( ...
    'fp', fpmat, 'fn', fnmat, 'tp', tpmat, ...
    'truematch', matchtruth, 'truemissing', missingtruth, ...
    'testmatch', matchtest, 'testmissing', missingtest );

end



%
%
% Plot detected events.


disp('-- Generating plots.');


%
% Common configuration.

figconfig = struct( ...
  'fig', figure, 'outdir', plotdir, ...
  'fsamp', fsamp, ...
  'psfres', 5, 'psolap', 99, 'psleak', 0.75, 'psylim', 50 );

plots_per_band = inf;
trial_stride = 25;
channel_stride = 1;


%
% Merge the "selected" event matrix so that it can be scatter-plotted.

% This should never match.
evcomparefuncfalse = @(evfirst, evsecond) deal(false, inf);

% Merge across trials and channels.
synthdetect_merged = ...
  wlAux_mergeTrialsChannels(synthdetect_selected, evcomparefuncfalse);

% Merge across bands.
bandlistwide = [ struct( 'band', [ 2 200 ], 'label', 'wb', 'name', 'Wide' ) ];
synthdetect_merged = ...
  wlAux_splitEvMatrixByBand(synthdetect_merged, bandlistwide);


%
% Event plots.


% Ground truth events.

wlPlot_plotAllMatrixEvents(figconfig, synthgt_byband, ...
  'Synthetic Ground Truth', 'synthgt', ...
  plots_per_band, trial_stride, channel_stride);


% Detected events for selected thresholds.

wlPlot_plotAllMatrixEvents(figconfig, synthdetect_selected, ...
  'Detected Events (Tuned Thresholds)', 'synthdet', ...
  plots_per_band, trial_stride, channel_stride);


%
% Detection rates vs. threshold.

for bidx = 1:length(bandlist)

  chartfp = [];
  chartfn = [];
  charttp = [];

  for thidx = 1:length(detsweepthresholds)

    thisconf = confstats{thidx};

    chartfp(thidx) = sum(sum( thisconf.fp(bidx,:,:) ));
    chartfn(thidx) = sum(sum( thisconf.fn(bidx,:,:) ));
    charttp(thidx) = sum(sum( thisconf.tp(bidx,:,:) ));

  end

  wlPlot_plotDetectCurves( figconfig, ...
    detsweepthresholds, 'Detection Threshold (dB)', ...
    [ struct( 'fp', chartfp, 'fn', chartfn, 'tp', charttp, ...
        'color', [ 0.0 0.4 0.7 ], 'label', 'magnitude detect' ) ], ...
    sprintf('Detected Synthetic Events - %s', bandlist(bidx).name), ...
    sprintf('thresh-%s', bandlist(bidx).label) );

end


%
% Scatter-plots of detected event parameters.

plotband = [ 3 150 ];
plotdur = [ 0 15 ];
plotamp = [ 1e-2 100 ];
wlPlot_plotEventScatterMulti( figconfig, ...
  [ struct( 'eventlist', synthdetect_merged.events{1}, ...
    'color', [ 0.0 0.4 0.7 ], 'legend', 'hand-tuned threshold') ], ...
  plotband, plotdur, plotamp, 'Detected Synthetic Events', 'synthdet' );


%
% There's a lot more that _can_ be plotted, but this example is long enough.
% See "do_ft_synth_plot.m" for more examples.



%
%
% Done.


disp('-- Done.');



%
% This is the end of the file.
