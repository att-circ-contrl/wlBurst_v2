% Field Trip-related test scripts - Synthetic FT data - Post-processing

%
%
% Includes.

% FIXME - Assume init has already been called.



%
%
% Configuration.


% Threshold decimation factor for plotting.
threshdecim = 2;


% Wave comparison functions.

wavecomparefuncwide = @(thisev, thiswave) ...
  wlProc_calcWaveErrorRelative( thiswave.ftwave, thisev.sampstart, ...
    thisev.wave, thisev.s1 );

wavecomparefuncbpf = @(thisev, thiswave) ...
  wlProc_calcWaveErrorRelative( thiswave.bpfwave, thisev.sampstart, ...
    thisev.wave, thisev.s1 );



%
%
% Compute relative RMS error (vs the BPF signal and WB signal).


groundftbyband = ...
  wlFT_calcEventErrors(groundftbyband, wavecomparefuncbpf, 'errbpf');
groundftbyband = ...
  wlFT_calcEventErrors(groundftbyband, wavecomparefuncwide, 'errwide');

threshcount = length(detectft_mag);
for thidx = 1:threshcount
  detectft_mag{thidx} = wlFT_calcEventErrors( ...
    detectft_mag{thidx}, wavecomparefuncbpf, 'errbpf' );
  detectft_mag{thidx} = wlFT_calcEventErrors( ...
    detectft_mag{thidx}, wavecomparefuncwide, 'errwide' );
end

threshcount = length(detectft_freq);
for thidx = 1:threshcount
  detectft_freq{thidx} = wlFT_calcEventErrors( ...
    detectft_freq{thidx}, wavecomparefuncbpf, 'errbpf' );
  detectft_freq{thidx} = wlFT_calcEventErrors( ...
    detectft_freq{thidx}, wavecomparefuncwide, 'errwide' );
end



%
%
% Plotting.

% FIXME - This should really be in do_ft_synth_plot.m, but keep it here to
% avoid having to save copies of the un-pruned event matrices.


if plot_ftsyn_raw_error

  wlPlot_plotMatrixErrorStats( figconfig, ...
    [ struct( 'evmatrix', groundftbyband, 'errfield', 'errwide', ...
      'legend', 'wideband', 'color', cbrn ), ...
      struct( 'evmatrix', groundftbyband, 'errfield', 'errbpf', ...
      'legend', 'bandpass', 'color', cblu ) ], ...
    'Synthetic Ground Truth Error', 'gt' );

  % FIXME - We want to plot this for "selected" thresholds, not all of them.
  % Right now selection happens after pruning, not before. Decimate instead.

  for thidx = 1:threshdecim:length(detsweepthresholds)
    thisdb = detsweepthresholds(thidx);

    wlPlot_plotMatrixErrorStats( figconfig, ...
      [ struct( 'evmatrix', detectft_mag{thidx}, 'errfield', 'errwide', ...
        'legend', 'mag wideband', 'color', ccyn ), ...
        struct( 'evmatrix', detectft_freq{thidx}, 'errfield', 'errwide', ...
        'legend', 'freq wideband', 'color', cyel ), ...
        struct( 'evmatrix', detectft_mag{thidx}, 'errfield', 'errbpf', ...
        'legend', 'mag bandpass', 'color', cblu ), ...
        struct( 'evmatrix', detectft_freq{thidx}, 'errfield', 'errbpf', ...
        'legend', 'freq bandpass', 'color', cbrn ) ], ...
      sprintf('Synthetic Detection Error (%d dB)', thisdb), ...
      sprintf('det-%02d', thisdb) );
  end

end



%
%
% Prune regions of parameter/error space with lots of false positives.


% FIXME - Throw out anything with BPF RMS error over 0.7.
% This is about the best we can do without losing many true positives.
% In combination with well-tuned thresholds, this does help.

passfunc = @(thisev) (0.7 >= thisev.auxdata.errbpf);

threshcount = length(detectft_mag);
for thidx = 1:threshcount
  detectft_mag{thidx} = wlAux_pruneMatrix(detectft_mag{thidx}, passfunc);
end

threshcount = length(detectft_freq);
for thidx = 1:threshcount
  detectft_freq{thidx} = wlAux_pruneMatrix(detectft_freq{thidx}, passfunc);
end



%
%
% This is the end of the file.
