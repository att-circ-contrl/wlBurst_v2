% Field Trip-related test scripts - Synthetic FT data - "Custom" - Detection.

%
%
% Includes.

% Assume that the parent called _init and _config.



%
%
% Event detection.


disp('== Detecting events using custom function.')
disp(sprintf( '-- (%dx%d patches)', ...
  length(threshsweep_xy), length(threshsweep_xy) ));
disp(datetime);


wavecomparefuncbpf = @(thisev, thiswave) ...
  wlProc_calcWaveErrorRelative( thiswave.bpfwave, thisev.sampstart, ...
    thisev.wave, thisev.s1 );
errpassfunc = @(thisev) (0.7 >= thisev.auxdata.errbpf);

clear detectft_union;
clear detectft_intersect;

patchtotal = length(threshsweep_xy) * length(threshsweep_xy);
patchcount = 0;

for thidxmag = 1:length(threshsweep_xy)
  for thidxfreq = 1:length(threshsweep_xy)

    patchcount = patchcount + 1;
    if tattlepatch
      disp(sprintf( '-- Checking XY sample %d of %d...', ...
        patchcount, patchtotal ));
    end


    for bidx = 1:length(bandlist)

      % FIXME - This might underrun "segdetendthresh" if ranges are strange.
      % Detection will still happen, but threshold is effectively clamped.

      threshmag = magthreshdb(bidx) + threshsweep_xy(thidxmag);
      threshfreq = freqthreshdb(bidx) + threshsweep_xy(thidxfreq);

      bandoverrides(bidx) = struct ( ...
        'seg', ...
          struct( 'thresh_mag', threshmag, 'thresh_freq', threshfreq ), ...
        'param', struct() );

      % FIXME - We can't override DC LPF in the nested configuration.
      % Well, we can, but we have to copy the entire daughter structure.

    end


    detect_temp = wlFT_doFindEventsInTrials_MT(traceft, bandlist, ...
      segconfig_union, paramconfig_increment, ...
      bandoverrides, tattledetect );
    detect_temp = wlFT_pruneEventsByTime(detect_temp, padtime, padtime);
    detect_temp = ...
      wlFT_calcEventErrors(detect_temp, wavecomparefuncbpf, 'errbpf');
    detect_temp = wlAux_pruneMatrix(detect_temp, errpassfunc);

    detectft_union{thidxmag, thidxfreq} = detect_temp;

    detect_temp = wlFT_doFindEventsInTrials_MT(traceft, bandlist, ...
      segconfig_intersect, paramconfig_increment, ...
      bandoverrides, tattledetect );
    detect_temp = wlFT_pruneEventsByTime(detect_temp, padtime, padtime);
    detect_temp = ...
      wlFT_calcEventErrors(detect_temp, wavecomparefuncbpf, 'errbpf');
    detect_temp = wlAux_pruneMatrix(detect_temp, errpassfunc);

    detectft_intersect{thidxmag, thidxfreq} = detect_temp;

  end
end


disp(datetime);
disp('== Finished detecting events.');



%
%
% This is the end of the file.
