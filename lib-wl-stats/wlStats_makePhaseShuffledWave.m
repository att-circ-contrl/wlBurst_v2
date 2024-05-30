function newwave = wlStats_makePhaseShuffledWave( oldwave )

% function newwave = wlStats_makePhaseShuffledWave( oldwave )
%
% This scrambles the phases of all components of a wave, smearing out
% position-related information while keeping the power spectrum the same.
%
% This is intended to be used for surrogate testing of burst detection. The
% rate at which spurious bursts appear by chance will be the same as with
% the original data.
%
% NOTE - Applying a rolloff window to the waveform data is recommended, as
% otherwise endpoint discontinuity will show up as sawtooth harmonics.
%
% "oldwave" is a vector containing waveform data.
%
% "newwave" is a vector containing phase-shuffled waveform data.


% FIXME - Complain and carry on if we're passed data with NaNs.

sampcount = length(oldwave);
nancount = sum(isnan(oldwave));

if nancount > 0
  disp(sprintf( ...
    '### [wlStats_makePhaseShuffledWave]  %d of %d samples were NaN!', ...
    nancount, sampcount ));

  % FIXME - Squash to zero instead of interpolating.
  oldwave(isnan(oldwave)) = 0;
end


% Get a phase-scrambling spectrum.

% Make sure the scrambling spectrum's real component is symmetrical and
% imaginary component is antisymmetrical, so that it's purely real in the
% time domain.

% Don't modify DC or (with an even number of samples) the Nyquist frequency.

wavespect = fft(oldwave);
phasespect = ones(size(wavespect));

% We want (N/2) - 1 if even, floor(N/2) if odd.
halfcount = floor( (sampcount - 1) / 2);

randphases = exp( i * rand([ 1 halfcount ]) * 2 * pi );

phasespect(2:(1 + halfcount)) = randphases;
phasespect = flip(phasespect);
phasespect(1:halfcount) = conj(randphases);
phasespect = flip(phasespect);


% Build the phase-shuffled wave.

newwave = ifft( wavespect .* phasespect );

% Force the type to real, rather than complex.
% The imaginary component should be zero, but small numerical errors may
% perturb that.
newwave = real(newwave);


% Done.

end


%
% This is the end of the file.
