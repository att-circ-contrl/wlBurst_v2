% Field Trip-related test scripts - Synthetic FT data - Configuration.

%
%
% Includes.

% NOTE - Assume the parent called "init" already.



%
%
% Configuration.



%
% Event detection.


% Select the parameter extraction algorithm we want.
% "coarse" gives a poor fit, "amp" takes a while but gives a good fit, and
% "both" takes a very long time and gives a slightly better fit than "amp".

%param_chosen_type = 'coarse';
%param_chosen_type = 'amp';
param_chosen_type = 'both';

% Use DC average for theta thresholds.
seg_use_dc = [ true false false false false ];

% Padding, to ignore roll-off events.
padtime = 0.50;



%
% Plotting.


% Select which plots we want to generate.

plot_ftsyn_gt_band = true;
plot_ftsyn_gt_wide = false;

plot_ftsyn_det_waves = true;
plot_ftsyn_det_rates = true;
plot_ftsyn_det_scatter = true;

plot_ftsyn_raw_error = false;
plot_ftsyn_pruned_error = true;



%
% Event detection details.

% Detection.
% NOTE - We'll be overriding "dbpeak".

segconfig_mag = struct( 'type', 'magdual', ...
  'qlong', segmagvarqlong, ...
  'qdrop', segmagdropoutq, 'qglitch', segmagglitchq, ...
  'dbpeak', 10, 'dbend', segdetendthresh );

segconfig_freq = struct( 'type', 'freqdual', ...
  'noiseband', segbandnoise, 'noisesnr', segnoisesnrchosen, ...
  'qlong', segfreqvarqlong, 'qshort', segfreqvarqshort, ...
  'qdrop', segfreqdropoutq, 'qglitch', segfreqglitchq, ...
  'dbpeak', 10, 'dbend', segdetendthresh );

% Parameter extraction.

paramconfig_coarse = struct( 'type', 'grid', 'gridsteps', 7 );

paramconfig_amp = struct( 'type', 'annealamp', 'gridsteps', 5, ...
  'matchfreq', matchfreq, 'matchamp', matchamp, ...
  'matchlength', matchlength, 'matcholap', matcholap, ...
  'tunnelmax', annealmaxtries, 'totalmax', annealmaxtotal );

% This takes longer to anneal, so double the allowed number of steps.
paramconfig_both = struct( 'type', 'annealboth', 'gridsteps', 5, ...
  'matchfreq', matchfreq, 'matchamp', matchamp, ...
  'matchlength', matchlength, 'matcholap', matcholap, ...
  'tunnelmax', annealmaxtries, 'totalmax', 2 * annealmaxtotal );



%
%
% This is the end of the file.
