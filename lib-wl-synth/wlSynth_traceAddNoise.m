function newdata = ...
  wlSynth_traceAddNoise(olddata, samprate, colortype, ...
    noisef1, noisef2, noisepower, powerf1, powerf2)

% function newdata = ...
%   wlSynth_traceAddNoise(olddata, samprate, colortype, ...
%     noisef1, noisef2, noisepower, powerf1, powerf2)
%
% This function adds noise to a signal.
%
% "olddata" is the signal to add noise to.
% "samprate" is the number of samples per second in the signal data.
% "colortype" is a noise color using the "dsp.ColoredNoise" conventions.
%   Typical values are "pink" and "white".
% "noisef1" is the lowest frequency present in the noise.
% "noisef2" is the highest frequency present in the noise.
% "noisepower" is the average noise power (measured with "bandpower").
% "powerf1" is the lowest frequency of the band-limited power measurement.
% "powerf2" is the highest frequency of the band-limited power measurement.
%
% "newdata" is a copy of "olddata" with appropriately scaled noise added.

errcode = 'ok';

%
% Sanity check arguments.

if (samprate <= 0)
  errcode = 'Need a positive sampling rate.';
elseif (noisef1 <= 0) || (noisef2 <= 0) || (noisef2 <= noisef1)
  errcode = 'Invalid noise frequency limits specified.';
elseif (noisepower <= 0)
  errcode = 'Need a positive noise power.';
elseif (powerf1 <= 0) || (powerf2 <= 0) || (powerf2 <= powerf1)
  errcode = 'Invalid power measurement frequency limits specified';
else


  % Get output size.
  sampcount = length(olddata);

  % Make a corresponding noise vector.
  noisegen = dsp.ColoredNoise('Color',colortype,'SamplesPerFrame',sampcount);
  noisevec = noisegen();
  % Turn this into a [1xN] vector.
  noisevec = noisevec.';

  % Band-pass filter the noise.
  % Default steepness is fine.
  % Default attenuation is 60 dB. For 16-bit precision, we want 100 dB.
  noisevec = bandpass(noisevec, [ noisef1 noisef2 ], samprate, ...
    'StopbandAttenuation', 100);

  % Scale the noise so that its band-limited power matches the power specified.
  pmeasured = bandpower(noisevec, samprate, [ powerf1 powerf2 ]);
  if (pmeasured > 0)
    pmeasured = sqrt(noisepower / pmeasured);
    noisevec = noisevec * pmeasured;
  end

  % Add the noise to the original signal.
  newdata = olddata + noisevec;


  % Finished.

end


%
% If we had an error, show a message.

if ~(strcmp(errcode,'ok'))
  disp(errcode)
end


%
% Done.

end

%
% This is the end of the file.
