% Field Trip-related test scripts - Synthetic FT data - "Custom" tests.
%
% This tests the ability to specify "custom" (lambda-function) segmentation
% and parameter extraction algorithms.
%
% See LICENSE.md for distribution information.

%
%
% Includes.

do_ft_init

% Grandfather in "synthetic trace" configuration.
do_ft_synth_config



%
%
% Configuration.


% Threshold sweep range for mag/freq neighbourhood.
% 1x1 for smoke tests, 3x3 for rough tests, 5x5 for the real thing.

threshsweep_xy = -4:2:4;
%threshsweep_xy = -2:2:2;
%threshsweep_xy = 0:0;

tattledetect = false;
tattlepatch = true;


% Minimum true positive rate of interest (as a fraction of the best
% true positive rate).
tpfracmin = 0.8;


% Use DC average for theta thresholds.
seg_use_dc = [ true false false false false ];

% Padding, to ignore roll-off events.
padtime = 0.50;


% Select which plots we want to generate.

plot_ftsyn_gt_band = false;
plot_ftsyn_gt_wide = false;

plot_ftsyn_det_waves = false;
plot_ftsyn_det_rates = true;
plot_ftsyn_det_scatter = true;

plot_raw_error = false;
plot_pruned_error = true;


% Segmentation configuration.
% Segmentation by combined magnitude and frequency.

segmentfunc_magfreq = @(wavedata, samprate, bpfband, segconfig) ...
  wlHelper_getEvSegmentsUsingMagFreq(wavedata, samprate, bpfband, segconfig);

segconfig_union = struct( 'type', 'custom', ...
  'segmentfunc', segmentfunc_magfreq, ...
  'config_mag', segconfig_mag, 'config_freq', segconfig_freq, ...
  'thresh_mag', 10, 'thresh_freq', 10, ...
  'operation', 'union' );

segconfig_intersect = struct( 'type', 'custom', ...
  'segmentfunc', segmentfunc_magfreq, ...
  'config_mag', segconfig_mag, 'config_freq', segconfig_freq, ...
  'thresh_mag', 10, 'thresh_freq', 10, ...
  'operation', 'intersect' );


% Parameter extraction configuration.
% Parameter extraction by incremental fitting.

paramfunc_increment = @(events, waves, samprate, paramconfig) ...
  wlHelper_getEvParamsIncremental(events, waves, samprate, paramconfig);

% FIXME - NYI.
paramconfig_increment = struct( 'type', 'custom', ...
  'paramfunc', paramfunc_increment );



%
%
% Event detection.


if ~exist('detectft_union', 'var')
  do_ft_custom_detect
end



%
%
% Compare to ground truth and tabulate statistics.


disp('== Comparing detected events to ground truth.');
disp(datetime);

clear statft_union;
clear statft_intersect;

clear listft_union;
clear listft_intersect;

for thidxmag = 1:length(threshsweep_xy)
  for thidxfreq = 1:length(threshsweep_xy)

    [fp, fn, tp, matchtruth, matchtest, missingtruth, missingtest ] = ...
      wlFT_compareMatrixEventsVsTruth( groundftbyband, ...
        detectft_union{thidxmag, thidxfreq}, evcomparefunc );

    listft_union{thidxmag, thidxfreq} = ...
      struct('hit', matchtest, 'miss', missingtest);

    for bidx = 1:length(bandlist)

      statft_union.fp(bidx, thidxmag, thidxfreq) = ...
        sum(sum(  fp(bidx,:,:) ));

      statft_union.fn(bidx, thidxmag, thidxfreq) = ...
        sum(sum(  fn(bidx,:,:) ));

      statft_union.tp(bidx, thidxmag, thidxfreq) = ...
        sum(sum(  tp(bidx,:,:) ));

    end


    [fp, fn, tp, matchtruth, matchtest, missingtruth, missingtest ] = ...
      wlFT_compareMatrixEventsVsTruth( groundftbyband, ...
        detectft_intersect{thidxmag, thidxfreq}, evcomparefunc );

    listft_intersect{thidxmag, thidxfreq} = ...
      struct('hit', matchtest, 'miss', missingtest);

    for bidx = 1:length(bandlist)

      statft_intersect.fp(bidx, thidxmag, thidxfreq) = ...
        sum(sum(  fp(bidx,:,:) ));

      statft_intersect.fn(bidx, thidxmag, thidxfreq) = ...
        sum(sum(  fn(bidx,:,:) ));

      statft_intersect.tp(bidx, thidxmag, thidxfreq) = ...
        sum(sum(  tp(bidx,:,:) ));

    end

  end
end


% Get tp and fp rates.

statft_union.tprate = statft_union.tp ./ (statft_union.tp + statft_union.fp);
statft_union.fprate = statft_union.fp ./ (statft_union.tp + statft_union.fp);

statft_intersect.tprate = ...
  statft_intersect.tp ./ (statft_intersect.tp + statft_intersect.fp);
statft_intersect.fprate = ...
  statft_intersect.fp ./ (statft_intersect.tp + statft_intersect.fp);


% Find the best true positive counts within false positive rate limits.

for bidx = 1:length(bandlist)

  bestmagthresh_union{bidx} = [];
  bestfreqthresh_union{bidx} = [];
  bestmagthresh_intersect{bidx} = [];
  bestfreqthresh_intersect{bidx} = [];

  tuplecount_union = 0;
  tuplecount_intersect = 0;

  tpbest_union = 0;
  tpbest_intersect = 0;

  % First pass: Find the best tp count with acceptable fp rate.

  for thidxmag = 1:length(threshsweep_xy)
    for thidxfreq = 1:length(threshsweep_xy)

      tpcount = statft_union.tp(bidx, thidxmag, thidxfreq);
      fprate = statft_union.fprate(bidx, thidxmag, thidxfreq);
      if (tpcount > tpbest_union) && (fprate <= eventerrmax)
        tpbest_union = tpcount;
      end

      tpcount = statft_intersect.tp(bidx, thidxmag, thidxfreq);
      fprate = statft_intersect.fprate(bidx, thidxmag, thidxfreq);
      if (tpcount > tpbest_intersect) && (fprate <= eventerrmax)
        tpbest_intersect = tpcount;
      end

    end
  end
% FIXME - Diagnostics.
disp(sprintf('.. Best %s:  (U) %d tp   (I) %d tp', bandlist(bidx).name, ...
tpbest_union, tpbest_intersect));

  % Second pass: Find all rates close to this.

  for thidxmag = 1:length(threshsweep_xy)
    for thidxfreq = 1:length(threshsweep_xy)

      tpcount = statft_union.tp(bidx, thidxmag, thidxfreq);
      fprate = statft_union.fprate(bidx, thidxmag, thidxfreq);

      thismag = threshsweep_xy(thidxmag) + magthreshdb(bidx);
      thisfreq = threshsweep_xy(thidxfreq) + freqthreshdb(bidx);

      if (tpcount > 0) && (fprate <= eventerrmax) ...
        && (tpcount >= tpbest_union * tpfracmin)
        tuplecount_union = tuplecount_union + 1;
        bestmagthresh_union{bidx}(tuplecount_union) = thismag;
        bestfreqthresh_union{bidx}(tuplecount_union) = thisfreq;
% FIXME - Diagnostics.
disp(sprintf('(U) %s - M %d F %d - tp %d fpr %.2f', bandlist(bidx).name, ...
thismag, thisfreq, tpcount, fprate));
      end

      tpcount = statft_intersect.tp(bidx, thidxmag, thidxfreq);
      fprate = statft_intersect.fprate(bidx, thidxmag, thidxfreq);

      if (tpcount > 0) && (fprate <= eventerrmax) ...
        && (tpcount >= tpbest_intersect * tpfracmin)
        tuplecount_intersect = tuplecount_intersect + 1;
        bestmagthresh_intersect{bidx}(tuplecount_intersect) = thismag;
        bestfreqthresh_intersect{bidx}(tuplecount_intersect) = thisfreq;
% FIXME - Diagnostics.
disp(sprintf('(I) %s - M %d F %d - tp %d fpr %.2f', bandlist(bidx).name, ...
thismag, thisfreq, tpcount, fprate));
      end

    end
  end

end


disp(datetime);
disp('== Finished comparing to ground truth.');



%
%
% Plotting.


disp('== Plotting.');
disp(datetime);


% Contour plots.

for bidx = 1:length(bandlist)

  clear tpcounts;
  clear fpcounts;

  tpcounts(:,:) = statft_union.tp(bidx,:,:);
  fpcounts(:,:) = statft_union.fp(bidx,:,:);

  wlHelper_plotContours( figconfig, tpcounts, fpcounts, ...
    threshsweep_xy + magthreshdb(bidx), ...
    threshsweep_xy + freqthreshdb(bidx), ...
    bestmagthresh_union{bidx}, bestfreqthresh_union{bidx}, ...
    sprintf( 'Mag union Freq - %s band', bandlist(bidx).name ), ...
    sprintf( 'combo-union-%s', bandlist(bidx).label ) );

  tpcounts(:,:) = statft_intersect.tp(bidx,:,:);
  fpcounts(:,:) = statft_intersect.fp(bidx,:,:);
  wlHelper_plotContours( figconfig, tpcounts, fpcounts, ...
    threshsweep_xy + magthreshdb(bidx), ...
    threshsweep_xy + freqthreshdb(bidx), ...
    bestmagthresh_intersect{bidx}, bestfreqthresh_intersect{bidx}, ...
    sprintf( 'Mag intersect Freq - %s band', bandlist(bidx).name ), ...
    sprintf( 'combo-intersect-%s', bandlist(bidx).label ) );

end


disp(datetime);
disp('== Finished plotting.');



%
%
% Helper functions.


% Contour plot of confusion matrix stats vs magnitude and frequency threshold.

function wlHelper_plotContours( cfg, ...
  tpcounts, fpcounts, magrange, freqrange, ...
  tuples_mag, tuples_freq, figtitle, filelabel )


  % Matrix indices are (Y,X). Y = mag thresh, X = freq thresh.
  [ xgrid, ygrid ] = meshgrid( freqrange, magrange );


  % FIXME - Kludge levels.

%  countlevels = [ 0.3 0.5 0.7 1.0 1.5 2 3 5 7 10 15 20 30 50 70 100 ...
  countlevels = [ 1 2 3 5 7 10 15 20 30 50 70 100 ...
    150 200 300 500 700 1000 1500 2000 3000 5000 7000 10000 ...
    15000 20000 30000 50000 70000 100000 ];


  % True positive count.

  figure(cfg.fig);
  clf('reset');


  contour(xgrid, ygrid, tpcounts, countlevels, 'ShowText', 'On');

  xlabel('Frequency Threshold (dB)');
  ylabel('Magnitude Threshold (dB)');

  title(sprintf('%s - TP count', figtitle));
  saveas( cfg.fig, sprintf('%s/contour-%s-tp.png', cfg.outdir, filelabel) );


  % False positive count.

  figure(cfg.fig);
  clf('reset');

  contour(xgrid, ygrid, fpcounts, countlevels, 'ShowText', 'On');

  xlabel('Frequency Threshold (dB)');
  ylabel('Magnitude Threshold (dB)');

  title(sprintf('%s - FP count', figtitle));
  saveas( cfg.fig, sprintf('%s/contour-%s-fp.png', cfg.outdir, filelabel) );


  % False positive rates with thresholds annotated.

  figure(cfg.fig);
  clf('reset');

  hold on;

  fprates = fpcounts ./ (fpcounts + tpcounts);

  contour(xgrid, ygrid, fprates, 'ShowText', 'On');

  scatter(tuples_mag, tuples_freq, [], [ 0.9 0.2 0.3 ]);

  hold off;

  xlabel('Frequency Threshold (dB)');
  ylabel('Magnitude Threshold (dB)');

  title(sprintf('%s - FP rate', figtitle));
  saveas( cfg.fig, ...
    sprintf('%s/contour-%s-fprate.png', cfg.outdir, filelabel) );


  %
  % Done.

end



% Segmentation by combined magnitude and frequency.
% "data" is the data trace to examine.
% "samprate" is the number of samples per second in the signal data.
% "bpfband" [min max] is the frequency band of interest. Edges may fade.
% "segconfig" is the segmentation algorithm configuration structure.
%   this contains the following fields:
%   "config_mag" is a segmentation configuration structure for
%     "wlProc_getEvSegmentsUsingMagDual()".
%   "config_freq" is a segmentation configuration structure for
%     "wlProc_getEvSegmentsUsingFreqDual()".
%   "thresh_mag" is an overriding value that replaces config_mag.dbpeak.
%   "thresh_freq" is an overriding value that replaces config_freq.dbpeak.
%   "operation" is "union" or "intersect", specifying how combined detection
%     is to occur.
%
% "events" is an array of event record structures per EVENTFORMAT.txt.
%   Only the following fields are provided:
%   "sampstart":  Sample index in "data" corresponding to burst nominal start.
%   "duration":   Time between burst nominal start and burst nominal stop.
%
% "waves" is a structure containing waveforms derived from "data":
%   "bpfwave" is the band-pass-filtered waveform.
%   "bpfmag", "bpffreq", and "bpfphase" are the analytic magnitude,
%     frequency, and phase of the bpf waveform.
%   "noisywave" is the noisy version of the bpf waveform.
%   "noisymag", "noisyfreq", and "noisyphase" are the analytic magnitude,
%     frequency, and phase of the noisy waveform.
%   "magpowerfast" is the rapidly-changing instantaneous power.
%   "magpowerslow" is the slowly-changing instantaneous power.
%   "fvarfast" is the rapidly-changing variance of the instantaneous frequency.
%   "fvarslow" is the slowly-changing variance of the instantaneous frequency.

function [ events, waves ] = wlHelper_getEvSegmentsUsingMagFreq( ...
  data, samprate, bpfband, segconfig )


  % FIXME - We don't have helper functions that return the detection vectors
  % directly, but we can compute them from the diagnostic waves, and then
  % run event detection manually.


  %
  % Do segmentation separately for magnitude and frequency.

  fnom = sqrt(bpfband(1) * bpfband(2));

  [ events_mag, waves_mag ] = wlProc_getEvSegmentsUsingMagDual( ...
    data, samprate, bpfband, ...
    segconfig.config_mag.qglitch / fnom, ...
    segconfig.config_mag.qdrop / fnom, ...
    segconfig.config_mag.qlong / fnom, ...
    segconfig.thresh_mag, ...
    segconfig.config_mag.dbend );

  [ events_freq, waves_freq ] = wlProc_getEvSegmentsUsingFreqDual( ...
    data, samprate, bpfband, ...
    segconfig.config_freq.noiseband, ...
    segconfig.config_freq.noisesnr, ...
    segconfig.config_freq.qglitch / fnom, ...
    segconfig.config_freq.qdrop / fnom, ...
    segconfig.config_freq.qlong / fnom, ...
    segconfig.config_freq.qshort / fnom, ...
    segconfig.thresh_freq, ...
    segconfig.config_freq.dbend );

  % Merge wave structures.

  waves = waves_freq;
  waves.magpowerfast = waves_mag.magpowerfast;
  waves.magpowerslow = waves_mag.magpowerslow;


  %
  % Calculate detection vectors.

  magfactor = 10^(segconfig.thresh_mag / 10);
  magend = 10^(segconfig.config_mag.dbend / 10);

  % Looking for magnitude power greater than average.
  detectmagpeak = waves.magpowerfast > (waves.magpowerslow * magfactor);
  detectmagend = waves.magpowerfast > (waves.magpowerslow * magend);

  % De-glitch the peak vector but not the end vector.
  % Project the peak vector on to the end vector instead.
  detectmagpeak = wlProc_calcDeGlitchedVector( detectmagpeak, ...
    round(samprate * segconfig.config_mag.qglitch / fnom), ...
    round(samprate * segconfig.config_mag.qdrop / fnom) );
  detectmagend = detectmagend | detectmagpeak;


  freqfactor = 10^(segconfig.thresh_freq / 10);
  freqend = 10^(segconfig.config_freq.dbend / 10);

  % Looking for frequency variance less than average.
  detectfreqpeak = waves.fvarslow > (waves.fvarfast * freqfactor);
  detectfreqend = waves.fvarslow > (waves.fvarfast * freqend);

  % De-glitch the peak vector but not the end vector.
  % Project the peak vector on to the end vector instead.
  detectfreqpeak = wlProc_calcDeGlitchedVector( detectfreqpeak, ...
    round(samprate * segconfig.config_freq.qglitch / fnom), ...
    round(samprate * segconfig.config_freq.qdrop / fnom) );
  detectfreqend = detectfreqend | detectfreqpeak;


  % Merge the two detection vectors.

  if strcmp('union', segconfig.operation)

    detectpeak = detectmagpeak | detectfreqpeak;
    detectend = detectmagend | detectfreqend;

  else
    if ~strcmp('intersect', segconfig.operation)
      disp(sprintf( ...
        '### Unrecognized operation "%s"; falling back on "intersect".', ...
        operation ));
    end

    detectpeak = detectmagpeak & detectfreqpeak;
    detectend = detectmagend & detectfreqend;

  end


  %
  % Get event segments from these detection vectors.

  % Look for low-to-high transitions followed by high-to-low transitions in
  % the endpoint detection vector.

  evcount = 0;
  foundlohi = false;

  for sidx = 2:length(detectend)

    if detectend(sidx) && ~detectend(sidx-1)

      % This is the start of a potential event.
      foundlohi = true;
      lastlohi = sidx;  % Index of the first "true" element.

    elseif foundlohi && detectend(sidx-1) && ~detectend(sidx)

      % This is the end of a potential event (just past the end).
      % See if it has above-peak elements.

      peaksubset = detectpeak(lastlohi:sidx-1);
      if 0 < sum(peaksubset)

        % This is a real event.
        thisevent = struct( 'sampstart', lastlohi, ...
          'duration', (sidx - lastlohi) / samprate, ...
          'samprate', samprate );

        evcount = evcount + 1;
        events(evcount) = thisevent;
      end

    end

  end

  % Make sure we have a return value.

  if 1 > evcount
    events = [];
  end


  %
  % Done.

end



% Parameter extraction by incremental fitting.
%
% FIXME - Documentation goes here.

function [ newevents, auxdata ] = wlHelper_getEvParamsIncremental( ...
  oldevents, waves, samprate, paramconfig )

  % FIXME - NYI. Kludging with manual grid search.

  newevents = wlProc_getEvParamsUsingHilbert( waves.bpfwave, samprate, ...
    waves.bpfmag, waves.bpffreq, waves.bpfphase, ...
    oldevents, 7 );

  auxdata = struct();

end


%
%
% This is the end of the file.
