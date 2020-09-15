% Field Trip-related test scripts - Synthetic FT data - Event detection.

%
%
% Includes.

% FIXME - Assume init has already been called.



%
%
% Configuration.


% Select the actual parameter extraction method to use.

paramconfig_chosen = paramconfig_coarse;

if strcmp('amp', param_chosen_type)

  disp('.. Using detection type "amp".');
  paramconfig_chosen = paramconfig_amp;

elseif strcmp('both', param_chosen_type)

  disp('.. Using detection type "both".');
  paramconfig_chosen = paramconfig_both;

else

  disp('.. Using detection type "coarse".');

end


% Band-specific parameter overrides.

for bidx = 1:length(bandlist)

  bandoverrides_mag(bidx) = struct( ...
    'seg', struct( 'dbpeak', magthreshdb(bidx) ), ...
    'param', struct() );

  bandoverrides_freq(bidx) = struct( ...
    'seg', struct( 'dbpeak', freqthreshdb(bidx) ), ...
    'param', struct() );

end


% Use DC average instead of "DC" LPF for the specified bands.

for bidx = 1:length(bandlist)
  if seg_use_dc(bidx)
    bandoverrides_mag(bidx).seg.qlong_freq = inf;
    bandoverrides_freq(bidx).seg.qlong_freq = inf;
  end
end



%
%
% Event detection.


disp('== Detecting using magnitude.');
disp(datetime);

clear detectft_mag;

for thidx = 1:length(detsweepthresholds)

  disp(sprintf( '-- Threshold:  %d dB', round(detsweepthresholds(thidx)) ));

  % Make a temporary copy of the "band overrides" structure, so that the
  % original stays intact.
  bandoverrides_test = bandoverrides_mag;
  for bidx = 1:length(bandlist)
    bandoverrides_test(bidx).seg.dbpeak = detsweepthresholds(thidx);
  end

  detect_temp = wlFT_doFindEventsInTrials_MT(traceft, bandlist, ...
    segconfig_mag, paramconfig_chosen, bandoverrides_test, true );

  % FIXME - Prune this, to avoid roll-off window issues.
  detect_temp = wlFT_pruneEventsByTime(detect_temp, padtime, padtime);

  % Save the result.
  detectft_mag{thidx} = detect_temp;

end


disp('== Detecting using frequency stability.');
disp(datetime);

clear detectft_freq;

for thidx = 1:length(detsweepthresholds)

  disp(sprintf( '-- Threshold:  %d dB', round(detsweepthresholds(thidx)) ));

  % Make a temporary copy of the "band overrides" structure, so that the
  % original stays intact.
  bandoverrides_test = bandoverrides_freq;
  for bidx = 1:length(bandlist)
    bandoverrides_test(bidx).seg.dbpeak = detsweepthresholds(thidx);
  end

  detect_temp = wlFT_doFindEventsInTrials_MT(traceft, bandlist, ...
    segconfig_freq, paramconfig_chosen, bandoverrides_test, true );

  % FIXME - Prune this, to avoid roll-off window issues.
  detect_temp = wlFT_pruneEventsByTime(detect_temp, padtime, padtime);

  detectft_freq{thidx} = detect_temp;

end


disp(datetime);
disp('== Finished detecting.');



%
% Save the results.

disp('-- Saving detected events to disk.')

% Main saved data is the array of detection matrices indexed by threshold.

% Also save the detection configuration information so that other scripts can
% use it without having to cut-and-paste or re-generate it.

% FIXME - Need to use "-v7.3", as decent-sized data gives detection
% structures that are > 2 GB.
% NOTE - '-nocompression' is faster but considerably larger.
% Use "whos detectft_mag detectft_freq" to see how large.

save( synth_fname_detect, ...
  'segconfig_mag', 'segconfig_freq', 'paramconfig_chosen', ...
  'bandoverrides_mag', 'bandoverrides_freq', ...
  'detectft_mag', 'detectft_freq', ...
  '-v7.3' );

disp('-- Finished saving detected events.')


%
%
% This is the end of the file.
