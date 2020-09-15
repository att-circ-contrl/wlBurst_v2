function newevents = wlProc_calcEventSNRs(data, samprate, oldevents)

% function newevents = wlProc_calcEventSNRs(data, samprate, oldevents)
%
% This function calculates the approximate signal-to-noise ratios of a list
% of detected events. The event waveform is reconstructed from its extracted
% paramters, and the power of the middle 80% is compared to the average power
% of the input waveform (which is assumed to be noise-dominated).
%
% "data" is the data trace to examine. This is typically band-pass filtered.
% "samprate" is the number of samples per second in the signal data.
% "oldevents" is the input event list. See EVENTFORMAT.txt for contents.
%
% "newevents" is a copy of the input list with the "snr" field filled in.


% NOTE - The trace should already be band-pass filtered.

% Get the in-band background power, for calculating nominal SNR.
% FIXME - Assuming the noise power is stationary and dominates the data.
noisepower = rms(data);
noisepower = noisepower * noisepower;


% Walk through the list, calculating SNRs event by event.

evcount = length(oldevents);

for evidx = 1:evcount

  thisevent = oldevents(evidx);

  % Make a copy of this event with the reconstructed waveform.
  % The new list does not get a copy of this.
  templist = wlAux_getReconFromParams([ thisevent ]);
  reconevent = templist(1);

  % Average the burst power over the middle 80%.
  samposet = round( 0.1 * (reconevent.s2 - reconevent.s1) );
  fitrange = (reconevent.s1 + samposet):(reconevent.s2 - samposet);
  sigpower = rms(reconevent.wave(fitrange));
  sigpower = sigpower * sigpower;

  newsnr = 0;
  if noisepower > 0
    newsnr = sigpower / noisepower;
    % We're in the power domain, so 10 dB/decade.
    newsnr = 10 * log10(newsnr);
  end

  thisevent.snr = newsnr;


  %
  % Done. Record the new event.

  newevents(evidx) = thisevent;


end  % Event list iteration.


% Make sure we have a return value.

if 1 > evcount
  newevents = [ ];
end


%
% Done.

end

%
% This is the end of the file.
