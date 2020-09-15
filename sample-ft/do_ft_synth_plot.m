% Field Trip-related test scripts - Synthetic FT data - Plotting

%
%
% Includes.

% FIXME - Assume init has already been called.



%
%
% Configuration.


% Scatter-plot ranges.

plotband = [ 0.5 * bandtheta(1) 1.5*bandgamma(2) ];
plotdur = [ 0 7 ];
plotamp = [ 1e-2 10 ];

% FIXME - Expand ranges, in case of plotting oddities.
if true
  plotdur = [ 0 15 ];
  plotamp = [ 1e-2 100 ];
end



%
%
% Plot ground truth events.


if plot_ftsyn_gt_band || plot_ftsyn_gt_wide
  disp('-- Plotting ground truth events.');
  disp(datetime);
end


% Per-band.

if plot_ftsyn_gt_band
  wlPlot_plotAllMatrixEvents(figconfig, groundftbyband, ...
    'Synthetic Ground Truth', 'ftgtbb', ...
    bandplots_max, stride_trial, stride_channel);
end

% Wideband.

if plot_ftsyn_gt_wide
  % FIXME - Manually tweak spectrum display.
  groundft.bandinfo(1).band = [ 1 50 ];

  wlPlot_plotAllMatrixEvents(figconfig, groundft, ...
    'Synthetic Ground Truth', 'ftgt', ...
    bandplots_max, stride_trial, stride_channel);
end



%
%
% Plot detected events.


if plot_ftsyn_det_waves

  disp('-- Plotting detected event waveforms.');
  disp(datetime);

  wlPlot_plotAllMatrixEvents(figconfig, detectft_mag_selected, ...
    'Synthetic Mag Detect', 'ftmag', ...
    bandplots_max, stride_trial, stride_channel);

  wlPlot_plotAllMatrixEvents(figconfig, detectft_freq_selected, ...
    'Synthetic Freq Detect', 'ftfreq', ...
    bandplots_max, stride_trial, stride_channel);

end



%
%
% Plot detection rates vs threshold.


if plot_ftsyn_det_rates

  disp('-- Plotting detection rate curves.');
  disp(datetime);

  for bidx = 1:length(bandlist)

    % Initialize.

    bandname = bandlist(bidx).name;
    bandlabel = bandlist(bidx).label;

    chartmagstats = struct( 'fp', [], 'fn', [], 'tp', [] );
    chartfreqstats = struct( 'fp', [], 'fn', [], 'tp', [] );


    % Compile statistics.

    for thidx = 1:length(detsweepthresholds)

      thisconf = ftgtstats_mag{thidx};

      chartmagstats.fp(thidx) = sum(sum( thisconf.fp(bidx,:,:) ));
      chartmagstats.fn(thidx) = sum(sum( thisconf.fn(bidx,:,:) ));
      chartmagstats.tp(thidx) = sum(sum( thisconf.tp(bidx,:,:) ));

      thisconf = ftgtstats_freq{thidx};

      chartfreqstats.fp(thidx) = sum(sum( thisconf.fp(bidx,:,:) ));
      chartfreqstats.fn(thidx) = sum(sum( thisconf.fn(bidx,:,:) ));
      chartfreqstats.tp(thidx) = sum(sum( thisconf.tp(bidx,:,:) ));

    end


    % Plot detection curves.

    wlPlot_plotDetectCurves( figconfig, ...
      detsweepthresholds, 'Detection Threshold (dB)', ...
      [ struct( 'fp', chartmagstats.fp, 'fn', chartmagstats.fn, ...
          'tp', chartmagstats.tp, ...
          'color', cblu, 'label', 'magnitude detect' ), ...
        struct( 'fp', chartfreqstats.fp, 'fn', chartfreqstats.fn, ...
          'tp', chartfreqstats.tp, ...
          'color', cbrn, 'label', 'frequency detect' ) ], ...
      sprintf('Magnitude- and Frequency-Based Detection - %s', bandname), ...
      sprintf('all-%s', bandlabel) );

  end  % Band iteration.

end



%
%
% Scatter-plot extracted and ground truth parameters.

if plot_ftsyn_det_scatter

  disp('-- Plotting detected vs ground truth parameters.');
  disp(datetime);

  %
  % Ground truth parameters.

  wlPlot_plotEventScatterMulti(figconfig, ...
    [ struct( 'eventlist', groundft_merged.events{1}, 'color', cgrn, ...
        'legend', 'ground truth' ) ], ...
    plotband, plotdur, plotamp, 'Synthetic FT - Ground Truth', 'gtruth' );


  %
  % Extracted parameters.


  clear scatterlist;

  for swidx = 1:length(plotthreshdbmag)
    scatterlist(swidx) = struct( ...
      'eventlist', detectft_mag_mergedswept(swidx).events{1}, ...
      'color', plotthreshcolors{swidx}, 'legend', ...
      sprintf('%s threshold', plotthreshnames{swidx}) );
  end

  wlPlot_plotEventScatterMulti( figconfig, scatterlist, ...
    plotband, plotdur, plotamp, ...
    'Synthetic FT - Magnitude Threshold Detection', 'mag-multi' );


  clear scatterlist;

  for swidx = 1:length(plotthreshdbfreq)
    scatterlist(swidx) = struct( ...
      'eventlist', detectft_freq_mergedswept(swidx).events{1}, ...
      'color', plotthreshcolors{swidx}, 'legend', ...
      sprintf('%s threshold', plotthreshnames{swidx}) );
  end

  wlPlot_plotEventScatterMulti( figconfig, scatterlist, ...
    plotband, plotdur, plotamp, ...
    'Synthetic FT - Frequency Stability Detection', 'freq-multi' );


  %
  % True and false positives.

  for swidx = 1:length(plotthreshdbmag)

    wlPlot_plotEventScatterMulti( figconfig, ...
      [ struct( ...
        'eventlist', ...
          ftgtstats_mag_mergedswept(swidx).testmissing.events{1}, ...
        'color', cbrn, 'legend', 'Incorrect' ), ...
        struct( ...
        'eventlist', ...
          ftgtstats_mag_mergedswept(swidx).testmatch.events{1}, ...
        'color', cblu, 'legend', 'Correct' ) ], ...
      plotband, plotdur, plotamp, ...
      sprintf('Synthetic FT - Magnitude Threshold - %s thresh', ...
        plotthreshnames{swidx}), ...
      sprintf('tpfp-mag-%s', plotthreshnames{swidx}) );

  end


  for swidx = 1:length(plotthreshdbfreq)

    wlPlot_plotEventScatterMulti( figconfig, ...
      [ struct( ...
        'eventlist', ...
          ftgtstats_freq_mergedswept(swidx).testmissing.events{1}, ...
        'color', cbrn, 'legend', 'Incorrect' ), ...
        struct( ...
        'eventlist', ...
          ftgtstats_freq_mergedswept(swidx).testmatch.events{1}, ...
        'color', cblu, 'legend', 'Correct' ) ], ...
      plotband, plotdur, plotamp, ...
      sprintf('Synthetic FT - Frequency Stability - %s thresh', ...
        plotthreshnames{swidx}), ...
      sprintf('tpfp-freq-%s', plotthreshnames{swidx}) );

  end


  %
  % Ground truth vs detected parameters.

  clear matchseriesmag;

  for swidx = 1:length(plotthreshdbmag)
    matchseriesmag(swidx) = struct( ...
      'truthlist', ftgtstats_mag_mergedswept(swidx).truematch.events{1}, ...
      'testlist', ftgtstats_mag_mergedswept(swidx).testmatch.events{1}, ...
      'color', plotthreshcolors{swidx}, ...
      'legend', sprintf('%s threshold', plotthreshnames{swidx}) );
  end

  wlPlot_plotEventXYMultiDual(figconfig, matchseriesmag, ...
    plotband, plotdur, plotamp, ...
    'Magnitude Threshold Detection', 'mag-xy' );

  clear matchseriesfreq;

  for swidx = 1:length(plotthreshdbfreq)
    matchseriesfreq(swidx) = struct( ...
      'truthlist', ftgtstats_freq_mergedswept(swidx).truematch.events{1}, ...
      'testlist', ftgtstats_freq_mergedswept(swidx).testmatch.events{1}, ...
      'color', plotthreshcolors{swidx}, ...
      'legend', sprintf('%s threshold', plotthreshnames{swidx}) );
  end

  wlPlot_plotEventXYMultiDual(figconfig, matchseriesfreq, ...
    plotband, plotdur, plotamp, ...
    'Frequency Stability Detection', 'freq-xy' );

end



%
%
% Plot reconstruction error.

if plot_ftsyn_pruned_error

  disp('-- Plotting waveform reconstruction error.');
  disp(datetime);


  for swidx = 1:length(plotthreshdbmag)

    wlPlot_plotMatrixErrorStats( figconfig, ...
      [ struct( 'evmatrix', ftgtstats_mag_swept(swidx).testmissing, ...
        'errfield', 'errbpf', 'legend', 'Incorrect', 'color', cbrn ), ...
        struct( 'evmatrix', ftgtstats_mag_swept(swidx).testmatch, ...
        'errfield', 'errbpf', 'legend', 'Correct', 'color', cblu ) ], ...
      sprintf('Synthetic FT Recon Error - Magnitude Detect - %s thresh', ...
        plotthreshnames{swidx}), ...
      sprintf('tpfp-mag-%s', plotthreshnames{swidx}) );

  end


  for swidx = 1:length(plotthreshdbfreq)

    wlPlot_plotMatrixErrorStats( figconfig, ...
      [ struct( 'evmatrix', ftgtstats_freq_swept(swidx).testmissing, ...
        'errfield', 'errbpf', 'legend', 'Incorrect', 'color', cbrn ), ...
        struct( 'evmatrix', ftgtstats_freq_swept(swidx).testmatch, ...
        'errfield', 'errbpf', 'legend', 'Correct', 'color', cblu ) ], ...
      sprintf('Synthetic FT Recon Error - Frequency Detect - %s thresh', ...
        plotthreshnames{swidx}), ...
      sprintf('tpfp-freq-%s', plotthreshnames{swidx}) );

  end

end



%
%
% Done.

disp(datetime);
disp('-- Finished plotting.');



%
%
% This is the end of the file.
