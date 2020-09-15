function [ newevent, error ] = wlProc_fitAmpBasic(hilmag, oldevent, atype)

% function [ newevent, error ] = wlProc_fitAmpBasic(hilmag, oldevent, atype)
%
% This function estimates oscillatory burst amplitude by curve fitting a
% logarithmic or linear ramp in the region of interest. Roll-on and roll-off
% are used if supplied, or fixed at 20% of the duration if not supplied (this
% function does not curve-fit the roll-on and roll-off).
%
% "hilmag" contains analytic signal instantaneous magnitude samples.
% "oldevent" is a record structure per EVENTFORMAT.txt. Required fields are:
%   "sampstart":  Sample index in the original recording waveform
%                 corresponding to event time 0.
%   "duration":   Time between the start and end of the event. This is where
%                 the curve fit is performed.
%   "samprate":   Number of samples per second in the input waveform.
%   Optional fields "rollon" and "rolloff" are used if present.
%
% "atype" is 'linear' or 'logarithmic', specifying the curve to fit. If it's
% omitted or set to 'auto', the option with least error is used.
%
% "newevent" is a record structure per EVENTFORMAT.txt. It contains the
% fields of "oldevent", as well as the following:
%   "a1":       Burst amplitude at nominal start.
%   "a2":       Burst amplitude at nominal stop.
%   "atype":    Amplitude ramp type.
%   "rollon":   Cosine roll-on time (copied or set to 0.2*duration).
%   "rolloff":  Cosine roll-off time (copied or set to 0.2*duration).
%
% "error" is the RMS error between the fitted amplitude and the magnitude
%   of the analytic signal.


%
% Copy the data we were given.

newevent = oldevent;


%
% Check that "atype" exists, and set it to 'auto' if not.

if ~exist('atype', 'var')
  atype = 'auto';
end


%
% FIXME - Special-case "auto" and recurse instead of calculating for it.

if strcmpi(atype, 'auto')

  [ eventlin, errlin ] = wlProc_fitAmpBasic(hilmag, oldevent, 'linear');
  [ eventlog, errlog ] = wlProc_fitAmpBasic(hilmag, oldevent, 'logarithmic');

  newevent = eventlin;
  error = errlin;

  if (errlog < errlin)

    newevent = eventlog;
    error = errlog;

  end

else

%
% Forced curve type. Proceed.


%
% If we don't have roll-on and roll-off times, set them.

if ~isfield(newevent, 'rollon')
  newevent.rollon = 0.2 * newevent.duration;
end

if ~isfield(newevent, 'rolloff')
  newevent.rolloff = 0.2 * newevent.duration;
end


%
% Build a copy of the roll-off window.
% Extract the portion that's within the event duration.

samponhalf = round(newevent.rollon * newevent.samprate);
sampon = samponhalf + samponhalf;
sampoffhalf = round(newevent.rolloff * newevent.samprate);
sampoff = sampoffhalf + sampoffhalf;

samptotal = round(newevent.duration * newevent.samprate);
sampwide = samptotal + samponhalf + sampoffhalf;

% Remember that indexing starts at 1, not 0.
rollwindowfull = ...
  wlProc_calcCosineWindow(1 + sampon, 1 + sampwide - sampoff, 1 + sampwide);
% The number of samples we have here is (samptotal + 1)
rollwindow = rollwindowfull((1 + samponhalf):(1 + samponhalf + samptotal));


%
% Get location.

% The number of samples we have here is (samptotal + 1)
sampfirst = oldevent.sampstart;
samplast = sampfirst + samptotal;

sampcount = 1 + samplast - sampfirst;

% FIXME - Use the whole range to fit. Otherwise we get spurious negative
% values at start/stop points which the reconstruction routine doesn't like.
if true
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
% Get nominal amplitude.
% Do this by fitting to analytic magnitude.

% Before fitting, divide magnitude by the window (remove window effects).
% We're within the 50% rise/fall points, so this is safe to do.

fitmag = hilmag(sampfirst:samplast);
fitmag = fitmag ./ rollwindow;

% Extract the to-fit portion.
fitidx = (sampfitfirst:sampfitlast) + 1 - sampfirst;
fitmag = fitmag(fitidx);


% FIXME - Hard-code a minimum non-negative amplitude value.
ampminval = 1.0e-9;


if strcmpi(atype, 'logarithmic')

  % Fit with a logarithmic ramp.

  newevent.atype = 'logarithmic';

  % FIXME - Force amplitude to be positive, so we can take the log.
  fitmag = max(fitmag, ampminval);

  % Do the fit using the polynomial fit function, for simplicity.
  % Our "time" series is the sample index, not actual time.

  fittimes = (sampfitfirst:sampfitlast) - sampfirst;
  logmag = log(fitmag);
  polymag = polyfit(fittimes, logmag, 1);

  lnbeta = polymag(1);
  a1coeff = exp(polymag(2));


  % Get the instantaneous magnitude at the nominal starting and ending times.
  % Record these in the event record.

  newmag = a1coeff * exp(lnbeta * fittimes);

  newevent.a1 = newmag(1);
  newevent.a2 = newmag(2);

else

  % Fit with a linear ramp.

  newevent.atype = 'linear';

  % Do the fit using the polynomial fit function, for simplicity.
  % Our "time" series is the sample index, not actual time.

  fittimes = (sampfitfirst:sampfitlast) - sampfirst;
  polymag = polyfit(fittimes, fitmag, 1);


  % Get the instantaneous magnitude at the nominal starting and ending times.
  % Record these in the event record.

  newmag = polyval(polymag, [ 1 sampcount ]);
  newevent.a1 = newmag(1);
  newevent.a2 = newmag(2);

  % FIXME - Force amplitude values to be positive.
  % If we're fitting on the middle 80%, occasionally a dipping curve gives
  % a negative endpoint value. The reconstruction routine doesn't like this.
  newevent.a1 = max(newevent.a1, ampminval);
  newevent.a2 = max(newevent.a2, ampminval);

end


% Reconstruct the instantaneous amplitude from this fit.
% Note that we're reconstructing over a larger sample range.
% Also note that we're using sample indices as "times".

% FIXME - Do we really want to calculate MSE over the entire envelope?
% Doing it between the midpoints may work better.

samprangestart = sampfirst - samponhalf;
samprangeend = samplast + sampoffhalf;

% NOTE - Clip range, if we're at the trace endpoints.
samprangestart = max(1, samprangestart);
samprangeend = min(length(hilmag), samprangeend);
samprangeoset = samprangestart - (sampfirst - samponhalf);

samprange = samprangestart:samprangeend;


fitmag = hilmag(samprange);
fittimes = samprange - sampfirst;
fitduration = samplast - sampfirst;

% NOTE - Formulae per makeOneBurst.

beta = (newevent.a2 - newevent.a1) / fitduration;
fitamp = fittimes .* beta + newevent.a1;

if strcmpi(newevent.atype, 'logarithmic')
  beta = (newevent.a2 / newevent.a1)^(1 / fitduration);
  fitamp = newevent.a1 * beta.^fittimes;
end

% Modulate by the roll-off window.
% NOTE - Truncate rolloff window if we're near the endpoints.
rollrange = samprange + 1 + samprangeoset - samprangestart;
fitamp = fitamp .* rollwindowfull(rollrange);


% Calculate the MSE.
error = rms(fitamp - fitmag);


%
% End of forced curve type.

end


%
% Done.

end

%
% This is the end of the file.
