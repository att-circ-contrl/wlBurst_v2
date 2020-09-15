function newevlist = wlAux_getReconFromWave(oldevlist, label)

% function newevlist = wlAux_getReconFromWave(oldevlist, label)
%
% This function fills in "times", "wave", "mag", "freq", and "phase" in a
% seires of event records by copying a set of signal traces stored in
% "auxwaves" that begin with the specified prefix. "s1" and "s2" are set to
% point to time 0 and time "duration", respectively.
%
% "oldevlist" is an array of event records per EVENTFORMAT.txt.
% "label" is the prefix to use when constructing "auxwaves" signal names.
% These names have "times", "wave", "mag", "freq", and "phase" appended to
% the label.
%
% "newevent" is an array of updated event records with "curve-fit waveform"
% fields filled in.

for eidx = 1:length(oldevlist)

  % Copy the original record. Worst-case, this is our fallback.
  newevent = oldevlist(eidx);

  % Construct field names.
  nametimes = strcat(label, 'times');
  namewave = strcat(label, 'wave');
  namemag = strcat(label, 'mag');
  namefreq = strcat(label, 'freq');
  namephase = strcat(label, 'phase');

  % Copy these fields only if all of them exist.
  auxwaves = newevent.auxwaves;
  if isfield(auxwaves, nametimes) && isfield(auxwaves, namewave) ...
    && isfield(auxwaves, namemag) && isfield(auxwaves, namefreq) ...
    && isfield(auxwaves, namephase)


    % Copy the waves.

    newevent.times = getfield(auxwaves, nametimes);
    newevent.wave = getfield(auxwaves, namewave);
    newevent.mag = getfield(auxwaves, namemag);
    newevent.freq = getfield(auxwaves, namefreq);
    newevent.phase = getfield(auxwaves, namephase);


    % Find the best approximations of the starting and ending sample times.

    newevent.s1 = 1;
    newevent.s2 = 1;
    realstop = newevent.duration;
    beststart = abs(newevent.times(1));
    beststop = abs(newevent.times(1) - realstop);

    for sidx = 2:length(newevent.times)

      thisval = newevent.times(sidx);

      if abs(thisval) < beststart
        beststart = abs(thisval);
        newevent.s1 = sidx;
      end

      if abs(thisval - realstop) < beststop
        beststop = abs(thisval - realstop);
        newevent.s2 = sidx;
      end

    end

  end

  % Store this event record.
  newevlist(eidx) = newevent;

end


% Make sure we have a list to return.
% This is only a problem if we're passed an empty list to begin with.

if ~exist('newevlist', 'var')

  newevlist = [];

end


% Done.

end

%
% This is the end of the file.
