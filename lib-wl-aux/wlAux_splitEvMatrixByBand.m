function newmatrix = wlAux_splitEvMatrixByBand(oldmatrix, bandlist)

% function newmatrix = wlAux_splitEvMatrixByBand(oldmatrix, bandlist)
%
% This function sorts an event matrix's events into a new set of frequency
% bands. Old per-band lists are merged and repartitioned. Event matrix format
% is described in EVMATRIX.txt.
%
% Old "auxdata" values are discarded. Old "waves" waveforms are discarded
% except for "ftwave" and "fttimes". Approximate band-pass-filtered analytic
% waveforms are then generated.
%
% "oldmatrix" is an event matrix containing the events to process.
% "bandlist" is an array containing band definition structures:
%   "band" [ min max ] defines a frequency band of interest.
%   "name" is a character array containing a human-readable band name.
%   "label" is a character array containing a filename-safe band ID string.
%
% "newmatrix" is an event matrix containing re-binned events.


% FIXME - Diagnostics.
dotattle = false;


%
% First pass: merge the old bands.


% FIXME - Diagnostics.
if dotattle
disp('.. Re-binning bands.')
disp(datetime);
end


[ oldbandcount trialcount chancount ] = size(oldmatrix.events);

falsecomparefunc = @(evfirst, evsecond) deal(false, inf);

minfreq = min(oldmatrix.bandinfo(1).band);
for bidx = 2:oldbandcount
  thismin = min(oldmatrix.bandinfo(bidx).band);
  if thismin < minfreq
    minfreq = thismin;
  end
end
bintime = round(20 / minfreq);
bintime = max(bintime, 1);

for tidx = 1:trialcount
  for cidx = 1:chancount

    wbwaves{tidx,cidx} = oldmatrix.waves{1,tidx,cidx}.ftwave;
    wbtimes{tidx,cidx} = oldmatrix.waves{1,tidx,cidx}.fttimes;

    % Index with parentheses to get a cell array slice out. Don't dereference.
    oldevlists = oldmatrix.events(:,tidx,cidx);
    wbevents{tidx,cidx} = wlAux_mergeEventLists(oldevlists, ...
      falsecomparefunc, bintime, 1);

  end
end



%
% Second pass: Construct the new event matrix.

bandcount = length(bandlist);


% Re-bin events.

bandcellarray = {};
for bidx = 1:length(bandlist)
  bandcellarray{bidx} = bandlist(bidx).band;
end

for tidx = 1:trialcount
  for cidx = 1:chancount

    thisoldlist = wbevents{tidx,cidx};
    thisnewlistlut = wlAux_splitEventsByBand(thisoldlist, bandcellarray);

    for bidx = 1:bandcount
      thisnewlist = thisoldlist(thisnewlistlut{bidx});
      newevents{bidx,tidx,cidx} = thisnewlist;
    end
  end
end


% FIXME - Diagnostics.
if dotattle
disp('.. Computing BPF and Hilbert waveforms.')
disp(datetime);
end


% Initialize wave data (approximate reconstruction of BPF/Hilbert).

for tidx = 1:trialcount
  for cidx = 1:chancount

    thiswave = wbwaves{tidx,cidx};
    thistimes = wbtimes{tidx,cidx};

    for bidx = 1:bandcount

      [ bpfwave, hilmag, hilfreq, hilphase ] = ...
        wlProc_calcBPFAnalytic( thiswave, oldmatrix.samprate, ...
          bandlist(bidx).band );

      newwaves{bidx,tidx,cidx} = struct( ...
        'ftwave', thiswave, 'fttimes', thistimes, ...
        'bpfwave', bpfwave, 'bpfmag', hilmag, ...
        'bpffreq', hilfreq, 'bpfphase', hilphase );

    end
  end
end


% Initialize auxiliary data (blank).

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount
      newaux{bidx,tidx,cidx} = struct();
    end
  end
end


% Save everything.

% Remember to wrap cell arrays in {} in the struct() call.

newmatrix = struct( 'bandinfo', bandlist, 'samprate', oldmatrix.samprate, ...
  'segconfigbyband', {oldmatrix.segconfigbyband}, ...
  'paramconfigbyband', {oldmatrix.paramconfigbyband}, ...
  'events', {newevents}, 'waves', {newwaves}, 'auxdata', {newaux});


% FIXME - Diagnostics.
if dotattle
disp('.. Done.')
disp(datetime);
end


%
% Done.

end


%
% This is the end of the file.
