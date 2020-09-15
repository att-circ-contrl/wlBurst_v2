function [ newevent, error ] = wlProc_fitFreqPhaseLinear( ...
  hilfreq, hilphase, oldevent)

% function [ newevent, error ] = wlProc_fitFreqPhaseLinear( ...
%   hilfreq, hilphase, oldevent)
%
% This function estimates oscillatory burst frequency and phase by curve
% fitting a linear ramp in the region of interest.
%
% "hilfreq" contains input signal instantaneous frequency samples.
% "hilphase" contains input signal instantaneous phase samples.
% "oldevent" is a record structure per EVENTFORMAT.txt. Required fields are:
%   "sampstart":  Sample index in the original recording waveform
%                 corresponding to event time 0.
%   "duration":   Time between the start and end of the event. This is where
%                 the curve fit is performed.
%   "samprate":   Number of samples per second in the input waveform.
%
% "newevent" is a record structure per EVENTFORMAT.txt. It contains the
% fields of "oldevent", as well as the following:
%   "f1":     Burst frequency at nominal start.
%   "f2":     Burst frequency at nominal stop.
%   "p1":     Burst phase at nominal start.
%   "p2":     Burst phase at nominal stop.
%   "ftype":  Frequency ramp type (set to "linear").
%
% "error" is the RMS phase error (with phase error being the difference
%   between original and reconstructed phases wrapped to -pi..pi).


%
% Copy the data we were given.

newevent = oldevent;


%
% Get location.

sampfirst = oldevent.sampstart;
samplast = sampfirst + round(oldevent.duration * oldevent.samprate);

sampcount = 1 + samplast - sampfirst;

% FIXME - We get spurious negative values at the start/stop points which the
% reconstruction routine doesn't like. This can be caused either by doing a
% linear fit to a concave curve, or by actual negative excursions caused by
% phase glitching.
if false
% Use the full range for fitting.

sampfitfirst = sampfirst;
sampfitlast = samplast;
else
% Use the middle 80% for fitting.
% FIXME - This should be a tuning parameter.

sampfitfirst = round(0.9 * sampfirst + 0.1 * samplast);
sampfitlast = round(0.1 * sampfirst + 0.9 * samplast);
end


%
% Get nominal frequency.
% This is line-fit to analytic frequency (a linearly chirped pulse).

newevent.ftype = 'linear';

% Do this using the polynomial fit function, for simplicity.
% Our "time" series is the sample index, not actual time.

fitfreq = hilfreq(sampfitfirst:sampfitlast);
fittimes = (sampfitfirst:sampfitlast) - sampfirst;
polyfreq = polyfit(fittimes, fitfreq, 1);


% Get the instantaneous frequency at the nominal starting and ending times.
% Record these in the event record.

newfreq = polyval(polyfreq, [ 1 sampcount ]);

% Record the fitted value at the starting and ending times.
newevent.f1 = newfreq(1);
newevent.f2 = newfreq(2);

if true
% FIXME - Nudge this if we went negative. This gives a worse fit!
newevent.f1 = max(newevent.f1, 1.0e-6);
newevent.f2 = max(newevent.f2, 1.0e-6);

% Revise the fit polynomial, so that we can calculate phase.
polyfreq = polyfit( [ 1 sampcount ], [ newevent.f1 newevent.f2 ], 1);
end


%
% Get nominal phase.

% This is non-trivial for two reasons. First, we can't just unwrap the
% input phase, because that may have glitches causing large jumps. Second,
% we have to make sure the phase fit exactly matches the frequency fit.

% The consistency requirement helps us. We know what the integral of the
% frequency line fit looks like; all we need is the constant of integration.
% We can find that by brute force.

fitphase = hilphase(sampfitfirst:sampfitlast);

polyphase(1) = 0.5 * polyfreq(1);
polyphase(2) = polyfreq(2);
polyphase(3) = 0;
polyphase = polyphase * 2 * pi / oldevent.samprate;

reconphase = polyval(polyphase, fittimes);

% FIXME - Do this by single-step brute force.
% Iterative would converge faster and more precisely, but only if there
% aren't any false minima far from the real one.

bestphase = NaN;
besterr = inf;
testphasestep = 0.01;

% Computing (recon + p0 - data), mod to -pi..pi, squared.
% The only part that varies is p0 (shifting "reconphase" by a constant).
% We can also call rms() as a proxy for squared error.

reconphase = reconphase - fitphase;

for testphase = 0:testphasestep:(2*pi)
  diffphase = reconphase + testphase;

  % Wrap to -pi..pi.
  diffphase = mod(diffphase + pi, 2*pi) - pi;

  thiserr = rms(diffphase);
  if thiserr < besterr
    bestphase = testphase;
    besterr = thiserr;
  end
end

polyphase(3) = bestphase;

% Reconstruct instantaneous phase from this fit.
% Note that we're reconstructing over a larger sample range.

newphase = polyval(polyphase, (1:sampcount));

% Wrap this to -pi..pi.
newphase = mod(newphase + pi, 2*pi) - pi;

% Record the fitted value at the starting and ending times.
newevent.p1 = newphase(1);
newevent.p2 = newphase(sampcount);

% Record the reconstruction error.
error = besterr;


%
% Done.

end

%
% This is the end of the file.
