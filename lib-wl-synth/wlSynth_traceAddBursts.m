function [newdata, events] = ...
  wlSynth_traceAddBursts(olddata, samprate, deflist)

% function [newdata, events] = ...
%   wlSynth_traceAddBursts(olddata, samprate, deflist)
%
% This function adds a series of oscillatory bursts to a data stream.
%
% "olddata" is the signal to add bursts to.
% "samprate" is the number of samples per second in the signal data.
% "deflist" is an array of burst type definition structures, with the
%   following fields (per BURSTTYPEDEF.txt):
%
%   "rate":                 Average number of bursts per second.
%   "snrrange": [min max]   Signal-to-noise ratio of bursts, in dB.
%   "noiseband": [min max]  Frequency band in which noise power is measured.
%   "durrange": [min max]   Burst duration in cycles (at average frequency).
%   "fctrrange": [min max]  Burst nominal center frequency.
%   "framprange": [min max] Ratio of ending/starting frequency.
%   "aramprange": [min max] Ratio of ending/starting amplitude.
%
% Burst parameters are defined using the conventions for
% wlSynth_makeOneBurst().
% Burst events are treated as a Poisson point process. For each event,
% parameters are chosen randomly within the specified ranges.
%
% "newdata" is a copy of "olddata" with burst events added.
% "events" is an array of structures with fields defined per EVENTFORMAT.txt.
% The following fields are filled in:
%
%   "sampstart":  Sample index in "newdata" corresponding to burst time 0.
%   "duration":   Time between 50% roll-on and 50% roll-off for the burst.
%   "s1":         Sample index in "wave" of nominal start (50% of roll-on).
%   "s2":         Sample index in "wave" of nominal stop (50% of roll-off).
%   "samprate":   Samples per second in the stored waveforms.
%   "snr":        Signal-to-noise ratio for this burst, in dB.
%
%   "paramtype"   Parameter fit type. For this function, it's "chirpramp".
%
%   "f1":         Burst frequency at nominal start.
%   "f2":         Burst frequency at nominal stop.
%   "a1":         Envelope amplitude at nominal start.
%   "a2":         Envelope amplitude at nominal stop.
%   "p1":         Phase at nominal start.
%   "p2":         Phase at nominal stop.
%
%   "rollon":     Duration of the envelope's cosine roll-on time.
%   "rolloff":    Duration of the envelope's cosine roll-off time.
%   "ftype":      Frequency ramp type.
%   "atype":      Amplitude ramp type.
%
%   In "auxwaves", the following waveforms:
%   "truthtimes": [1xN] array of burst sample times, relative to 50% roll-on.
%   "truthwave":  [1xN] array of ground-truth burst samples.
%   "truthmag":   [1xN] array with ground-truth burst envelope magnitude.
%   "truthfreq":  [1xN] array with ground-truth instantaneous frequency.
%   "truthphase": [1xN] array with ground-truth instantaneous phase (radians).

% Initialize.

newdata = olddata;
datasize = length(olddata);

evcount = 0;


% Calculate band power for each definition record.
% Calculate other derived quantities while we're at it.

for didx = 1:length(deflist)
  deflist(didx).noisepower = ...
    bandpower( olddata, samprate, deflist(didx).noiseband );

  deflist(didx).noiserms = sqrt( deflist(didx).noisepower );

  deflist(didx).chancepersample = deflist(didx).rate / samprate;
end


% Walk through samples, generating bursts at the desired rates.
% Do this the brute force way (checking for generation at each sample).
% We could instead draw intervals from the Poisson distribution, but that
% gives us multiple event lists that would have to be merged.

for sidx = 1:datasize
  for didx = 1:length(deflist)
    if rand <  deflist(didx).chancepersample

      % Generate an instance of this type of burst.

      thisdef = deflist(didx);


      %
      % Calculate parameters for this instance.

      % Limits are in the log domain, so use a uniform distribution.
      burstsnr = thisdef.snrrange(1) ...
        + rand * ( thisdef.snrrange(2) - thisdef.snrrange(1) );
      % Convert this to a target RMS value.
      burstrms = thisdef.noiserms * 10^(burstsnr / 20);

      % Remaining limits are in the linear domain but should be drawn using
      % a log distribution (to handle diverse scales well).

      duration = log(thisdef.durrange(1)) ...
        + rand * ( log(thisdef.durrange(2)) - log(thisdef.durrange(1)) );
      duration = exp(duration);

      fcenter = log(thisdef.fctrrange(1)) ...
        + rand * ( log(thisdef.fctrrange(2)) - log(thisdef.fctrrange(1)) );
      fcenter = exp(fcenter);

      frampscale = log(thisdef.framprange(1)) ...
        + rand * ( log(thisdef.framprange(2)) - log(thisdef.framprange(1)) );
      frampscale = exp(frampscale);

      arampscale = log(thisdef.aramprange(1)) ...
        + rand * ( log(thisdef.aramprange(2)) - log(thisdef.aramprange(1)) );
      arampscale = exp(arampscale);

      % Frequency needs to split the difference from the center.
      % Amplitude doesn't, since it gets rescaled to match desired power.

      f1 = fcenter / sqrt(frampscale);
      f2 = fcenter * sqrt(frampscale);

      a1 = 1.0;
      a2 = arampscale;

      % Phase is arbitrary.
      p1 = rand * 2 * pi;


      %
      % Generate a burst with the desired traits.

      [ errcode, times, wave, mag, freq, phase ] = ...
        wlSynth_makeOneBurst_Simple(samprate, f1, f2, a1, a2, p1, duration);

      % Figure out our time = 0 and time = duration sample indices.
      widx1 = 1 + round( - times(1) * samprate );
      % FIXME - Take advantage of the fact that roll-on and roll-off times
      % are the same.
      widx2 = times(1) + times(length(times)); % Gives duration in seconds.
      widx2 = widx1 + round(widx2 * samprate);

      % Scale the burst to match the desired RMS amplitude.
      scalefactor = burstrms / rms( wave(widx1:widx2) );
      wave = wave * scalefactor;
      mag = mag * scalefactor;
      a1 = a1 * scalefactor;
      a2 = a2 * scalefactor;


      %
      % Add this to the new data trace, and update the event log.

      % First, make sure this doesn't overlap either end.

      widx3 = length(times) - widx1;

      if (sidx >= widx1) && ((sidx + widx3) <= datasize)
        % The burst fits within the limits of the data trace. Proceed.

        newdata( (1 + sidx - widx1):(sidx + widx3) ) = ...
          newdata( (1 + sidx - widx1):(sidx + widx3) ) + wave;

        newevent.snr = burstsnr;
        newevent.sampstart = sidx;
        newevent.samprate = samprate;


        newevent.s1 = widx1;
        newevent.s2 = widx2;

        newevent.duration = times(widx2) - times(widx1);

        newevent.paramtype = 'chirpramp';

        newevent.a1 = a1;
        newevent.a2 = a2;

        % We need to copy p2 from the burst waveform data.
        % Copy the other frequency and phase values as well, to ensure
        % consistency.

        newevent.f1 = freq(widx1);
        newevent.f2 = freq(widx2);
        newevent.p1 = phase(widx1);
        newevent.p2 = phase(widx2);


        % FIXME - This uses knowledge of "makeOneBurst_Simple" and
        % "makeOneBurst".
        fmid = 0.5 * (newevent.f1 + newevent.f2);
        newevent.rollon = 1 / fmid;
        newevent.rolloff = 1 / fmid;
        newevent.ftype = 'logarithmic';
        newevent.atype = 'logarithmic';

        % Copy ground-truth waveforms.

        newevent.auxwaves = struct( ...
          'truthtimes', times, 'truthwave', wave, ...
          'truthmag', mag, 'truthfreq', freq, 'truthphase', phase );

        % Finished with this event.

        evcount = evcount + 1;
        events(evcount) = newevent;

      end  % Data trace bounds check.
    end  % "Do we want to generate a burst" check.
  end  % Iterating through burst types.
end  % Iterating through samples in the data trace.


% Make sure we're returning something.

if 1 > evcount
  events = [];
end


%
% Done.

end

%
% This is the end of the file.
