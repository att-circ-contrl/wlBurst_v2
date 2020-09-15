function newevlist = wlAux_getReconFromParams(oldevlist)

% function newevlist = wlAux_getReconFromParams(oldevlist)
%
% This function fills in "times", "wave", "mag", "freq", and "phase" in a
% seires of event records by calling wlSynth_makeOneBurst() using the
% extracted event parameters. s1 and s2 are adjusted accordingly.
% The new wave is also stored in "auxwaves" with the prefix "param".
%
% "oldevlist" is an array of event records per EVENTFORMAT.txt.
%
% "newevent" is an array of updated event records with "curve-fit waveform"
% fields filled in.


% First pass: Create reconstructed waves in "auxwaves" with the prefix
% "param".

for eidx = 1:length(oldevlist)

  % Copy the original record.
  newevent = oldevlist(eidx);


  % Switch based on the type of parametric description.

  if strcmp('chirpramp', newevent.paramtype)

    % This is a "chirped ramp" parametric description.

    % Wrap wlSynth_makeOneBurst() and save the results in auxwaves.

    [ errcode, times, wave, mag, freq, phase ] = ...
      wlSynth_makeOneBurst(newevent.duration, ...
        newevent.rollon, newevent.rolloff, newevent.samprate, ...
        newevent.f1, newevent.f2, newevent.ftype, ...
        newevent.a1, newevent.a2, newevent.atype, ...
        newevent.p1 );

    newevent.auxwaves.paramtimes = times;
    newevent.auxwaves.paramwave = wave;
    newevent.auxwaves.parammag = mag;
    newevent.auxwaves.paramfreq = freq;
    newevent.auxwaves.paramphase = phase;

    % Store this event record.
    if strcmp('ok', errcode)
      newevlist(eidx) = newevent;
    end

  else
    disp(sprintf( ...
      '### [wlAux_getReconFromParams]  Unrecognized type "%s".', ...
      newevent.paramtype ));
  end

end


% Make sure we have a new list.
% This is only a problem if we're passed an empty list to begin with.

if ~exist('newevlist', 'var')
  newevlist = [];
end


% Second pass: Wrap getReconFromWave() to copy this back and set s1 and s2.

newevlist = wlAux_getReconFromWave(newevlist, 'param');


% Done.

end

%
% This is the end of the file.
