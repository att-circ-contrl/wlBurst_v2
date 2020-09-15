% Field Trip-related test scripts - Synthetic FT data - Calculation

%
%
% Includes.

% FIXME - Assume init has already been called.



%
%
% Get event results for the "chosen" threshold values.


disp('-- Selecting event lists with chosen thresholds.');


detectft_mag_selected = detectft_mag{1};
detectft_freq_selected = detectft_freq{1};


%
% Selected thresholds.

for bidx = 1:length(bandlist)

  thidx = do_ft_calcFindThresholdIndex(magthreshdb(bidx), detsweepthresholds);

  detectft_mag_selected.events(bidx,:,:) = ...
    detectft_mag{thidx}.events(bidx,:,:);


  thidx = do_ft_calcFindThresholdIndex(freqthreshdb(bidx), detsweepthresholds);

  detectft_freq_selected.events(bidx,:,:) = ...
    detectft_freq{thidx}.events(bidx,:,:);

end


%
% Low/medium/high thresholds near the selected thresholds.

for swidx = 1:length(plotthreshdbmag)

  detectft_mag_swept(swidx) = detectft_mag_selected;

  for bidx = 1:length(bandlist)

    thidx = do_ft_calcFindThresholdIndex( ...
      magthreshdb(bidx) + plotthreshdbmag(swidx), detsweepthresholds);
    detectft_mag_swept(swidx).events(bidx,:,:) = ...
      detectft_mag{thidx}.events(bidx,:,:);

  end

end

for swidx = 1:length(plotthreshdbfreq)

  detectft_freq_swept(swidx) = detectft_freq_selected;

  for bidx = 1:length(bandlist)

    thidx = do_ft_calcFindThresholdIndex( ...
      freqthreshdb(bidx) + plotthreshdbfreq(swidx), detsweepthresholds);
    detectft_freq_swept(swidx).events(bidx,:,:) = ...
      detectft_freq{thidx}.events(bidx,:,:);

  end

end


%
% Collapsed event lists, merging across all axes.
% FIXME - This can take O(n^2) time!

% NOTE - This produces overlapping events. The result is only useful for
% statistics and plotting; comparing it against ground truth will lose most
% of the events (they'll be flagged as false positives).


% NOTE - Collapsing ground truth, too.
% Starting with the wideband version, so already one band.
groundft_merged = wlAux_mergeTrialsChannels(groundft, evcomparefuncfalse);

detectft_mag_mergedselect = wlAux_splitEvMatrixByBand( ...
  wlAux_mergeTrialsChannels(detectft_mag_selected, evcomparefuncfalse), ...
  bandlistwide );

for swidx = 1:length(detectft_mag_swept)
  detectft_mag_mergedswept(swidx) = wlAux_splitEvMatrixByBand( ...
    wlAux_mergeTrialsChannels( ...
      detectft_mag_swept(swidx), evcomparefuncfalse ), ...
    bandlistwide );
end

detectft_freq_mergedselect = wlAux_splitEvMatrixByBand( ...
  wlAux_mergeTrialsChannels(detectft_freq_selected, evcomparefuncfalse), ...
  bandlistwide );

for swidx = 1:length(detectft_freq_swept)
  detectft_freq_mergedswept(swidx) = wlAux_splitEvMatrixByBand( ...
    wlAux_mergeTrialsChannels( ...
      detectft_freq_swept(swidx), evcomparefuncfalse ), ...
    bandlistwide );
end


disp('-- Finished selecting events.');



%
%
% Get confusion matrix counts and lists.

% This is fast to compute, and quite large. Matlab doesn't want to save it.
% Saving can be forced by using version 7.3 and up, but there's no need to.


disp('-- Computing confusion matrix statistics.')
disp(datetime);


%
% Per-threshold statistics, across channels and trials and bands.

clear ftgtstats_mag;
clear ftgtstats_freq;

for thidx = 1:length(detsweepthresholds)

  [ fpmat fnmat tpmat matchtruth matchtest missingtruth missingtest ] = ...
    wlFT_compareMatrixEventsVsTruth( ...
      groundftbyband, detectft_mag{thidx}, evcomparefunc );
  ftgtstats_mag{thidx} = struct( ...
    'fp', fpmat, 'fn', fnmat, 'tp', tpmat, ...
    'truematch', matchtruth, 'truemissing', missingtruth, ...
    'testmatch', matchtest, 'testmissing', missingtest );

  [ fpmat fnmat tpmat matchtruth matchtest missingtruth missingtest ] = ...
    wlFT_compareMatrixEventsVsTruth( ...
      groundftbyband, detectft_freq{thidx}, evcomparefunc );
  ftgtstats_freq{thidx} = struct( ...
    'fp', fpmat, 'fn', fnmat, 'tp', tpmat, ...
    'truematch', matchtruth, 'truemissing', missingtruth, ...
    'testmatch', matchtest, 'testmissing', missingtest );

end


%
% Statistics with selected thresholds, across channels and trials and bands.


% Single "chosen" threshold.

[ fpmat fnmat tpmat matchtruth matchtest missingtruth missingtest ] = ...
  wlFT_compareMatrixEventsVsTruth( ...
    groundftbyband, detectft_mag_selected, evcomparefunc );
ftgtstats_mag_selected = struct( ...
  'fp', fpmat, 'fn', fnmat, 'tp', tpmat, ...
  'truematch', matchtruth, 'truemissing', missingtruth, ...
  'testmatch', matchtest, 'testmissing', missingtest );

[ fpmat fnmat tpmat matchtruth matchtest missingtruth missingtest ] = ...
  wlFT_compareMatrixEventsVsTruth( ...
    groundftbyband, detectft_freq_selected, evcomparefunc );
ftgtstats_freq_selected = struct( ...
  'fp', fpmat, 'fn', fnmat, 'tp', tpmat, ...
  'truematch', matchtruth, 'truemissing', missingtruth, ...
  'testmatch', matchtest, 'testmissing', missingtest );


% "Low"/"middle"/"high" thresholds.

clear ftgtstats_mag_swept;
clear ftgtstats_freq_swept;

for swidx = 1:length(plotthreshdbmag)

  [ fpmat fnmat tpmat matchtruth matchtest missingtruth missingtest ] = ...
    wlFT_compareMatrixEventsVsTruth( ...
      groundftbyband, detectft_mag_swept(swidx), evcomparefunc );
  ftgtstats_mag_swept(swidx) = struct( ...
    'fp', fpmat, 'fn', fnmat, 'tp', tpmat, ...
    'truematch', matchtruth, 'truemissing', missingtruth, ...
    'testmatch', matchtest, 'testmissing', missingtest );

end

for swidx = 1:length(plotthreshdbfreq)

  [ fpmat fnmat tpmat matchtruth matchtest missingtruth missingtest ] = ...
    wlFT_compareMatrixEventsVsTruth( ...
      groundftbyband, detectft_freq_swept(swidx), evcomparefunc );
  ftgtstats_freq_swept(swidx) = struct( ...
    'fp', fpmat, 'fn', fnmat, 'tp', tpmat, ...
    'truematch', matchtruth, 'truemissing', missingtruth, ...
    'testmatch', matchtest, 'testmissing', missingtest );

end


%
% Statistics with selected thresholds, merged into one trial/channel/band.

% NOTE - This produces overlapping events. The result is only useful for
% statistics and plotting; comparing it against ground truth will lose most
% of the events (they'll be flagged as false positives).


% Single "chosen" threshold.

ftgtstats_mag_mergedselect = wlHelper_collapseStats( ...
  ftgtstats_mag_selected, bandwide, evcomparefuncfalse );

ftgtstats_freq_mergedselect = wlHelper_collapseStats( ...
  ftgtstats_freq_selected, bandwide, evcomparefuncfalse );


% "Low"/"middle"/"high" thresholds.

clear ftgtstats_mag_mergedswept;
clear ftgtstats_freq_mergedswept;

for swidx = 1:length(plotthreshdbmag)
  ftgtstats_mag_mergedswept(swidx) = wlHelper_collapseStats( ...
    ftgtstats_mag_swept(swidx), bandwide, evcomparefuncfalse );
end

for swidx = 1:length(plotthreshdbfreq)
  ftgtstats_freq_mergedswept(swidx) = wlHelper_collapseStats( ...
    ftgtstats_freq_swept(swidx), bandwide, evcomparefuncfalse );
end


%
% Done.

disp(datetime);
disp('-- Finished computing statistics.')



%
%
% Helper functions.


% This function collapses confusion matrix statistics and lists across bands,
% trials, and channels.
%
% NOTE - This produces overlapping events. The result is only useful for
% statistics and plotting; comparing it against ground truth will lose most
% of the events (they'll be flagged as false positives).
%
% "oldstats" is a statistics structure of the type used above.
% "banddef" [ min max ] defines the single output band (usually wideband).
% "comparefunc" is a function used to determine when events should be merged
%   (i.e. duplicates). Form is per COMPAREFUNC.txt.

function newstats = wlHelper_collapseStats(oldstats, banddef, comparefunc)

  matchtruth =   oldstats.truematch;
  missingtruth = oldstats.truemissing;
  matchtest =    oldstats.testmatch;
  missingtest =  oldstats.testmissing;

  bandlist = [ struct( 'band', banddef, 'label', 'all', 'name', 'Merged' ) ];


  % Before doing the merge: annotate the "match" lists with position
  % information.

  truthcount = 0;
  testcount = 0;

  % Size is the same for both lists.
  [ bandcount trialcount chancount ] = size(matchtruth.events);

  for bidx = 1:bandcount
    for tidx = 1:trialcount
      for cidx = 1:chancount

        thislist = matchtruth.events{bidx, tidx, cidx};
        for eidx = 1:length(thislist)
          truthcount = truthcount + 1;
          thislist(eidx).auxdata.matchidx = truthcount;
        end
        matchtruth.events{bidx, tidx, cidx} = thislist;

        thislist = matchtest.events{bidx, tidx, cidx};
        for eidx = 1:length(thislist)
          testcount = testcount + 1;
          thislist(eidx).auxdata.matchidx = testcount;
        end
        matchtest.events{bidx, tidx, cidx} = thislist;

      end
    end
  end


  % Merge lists.

  matchtruth = wlAux_splitEvMatrixByBand( ...
    wlAux_mergeTrialsChannels(matchtruth, comparefunc), bandlist );
  missingtruth = wlAux_splitEvMatrixByBand( ...
    wlAux_mergeTrialsChannels(missingtruth, comparefunc), bandlist );
  matchtest = wlAux_splitEvMatrixByBand( ...
    wlAux_mergeTrialsChannels(matchtest, comparefunc), bandlist );
  missingtest = wlAux_splitEvMatrixByBand( ...
    wlAux_mergeTrialsChannels(missingtest, comparefunc), bandlist );


  % Put the match lists in consistent order.
  % FIXME - They're no longer sorted by starting sample time this way.

  thislist = matchtruth.events{1,1,1};
  if 0 < length(thislist)

    idxlist = [];
    for eidx = 1:length(thislist)
      idxlist(eidx) = thislist(eidx).auxdata.matchidx;
    end
    [ sortedidx sortedidxlut ] = sort(idxlist);
    matchtruth.events{1,1,1} = thislist(sortedidxlut);

  end

  thislist = matchtest.events{1,1,1};
  if 0 < length(thislist)

    idxlist = [];
    for eidx = 1:length(thislist)
      idxlist(eidx) = thislist(eidx).auxdata.matchidx;
    end
    [ sortedidx sortedidxlut ] = sort(idxlist);
    matchtest.events{1,1,1} = thislist(sortedidxlut);

  end


  % Build the new statistics structure.

  newstats = struct( ...
    'fp', length(missingtest.events{1,1,1}), ...
    'fn', length(missingtruth.events{1,1,1}), ...
    'tp', ...
      min( length(matchtruth.events{1,1,1}), ...
        length(matchtest.events{1,1,1}) ), ...
    'truematch', matchtruth, 'truemissing', missingtruth, ...
    'testmatch', matchtest, 'testmissing', missingtest );

% Done.

end


%
%
% This is the end of the file.
