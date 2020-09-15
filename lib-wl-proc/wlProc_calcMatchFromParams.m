function [ ismatch distance dvec cnames ] = ...
  wlProc_calcMatchFromParams(evfirst, evsecond, ...
    freqratiomax, ampratiomax, lenratiomax, olapfracmin)

% function [ ismatch distance ] = ...
%   wlProc_calcMatchFromParams(evfirst, evsecond, ...
%     freqratiomax, ampratiomax, lenratiomax, olapfracmin)
%
% This function compares two event records, indicating whether or not they
% "match" (represent the same event), and calculating a "distance" measure
% between them (with smaller values indicating a closer match).
% Distance and match state are computed using extracted parametric burst
% parameters (starting and ending time, amplitude, and frequency).
%
% "evfirst" and "evsecond" are event records to compare. See EVENTFORMAT.txt
%   for a description of record fields.
% "freqratiomax" is the maximum frequency ratio between matching events.
% "ampratiomax" is the maximum amplitude ratio between matching events.
% "lenratiomax" is the maximum duration ratio between matching events.
% "olapfracmin" is the minimum fraction of the shorter event that must be
%   covered by the longer event for a match to be accepted.
%
% "ismatch" is a boolean value that is "true" if the events match.
% "distance" is a non-negative real value representing how far apart the
%   events are. Smaller values indicate a closer match.
% "dvec" is a vector representing the distance between the two events.
%   Components of this vector typically represent axes of parameter space.
% "cnames" is a cell array containing label strings naming the distance
%   vector components.


% Compute frequency, amplitude, length, and overlap ratios.
% These are >= 1, >= 1, >= 1, and <= 1 respectively.


% Frequency ratio should be in the range 1..inf.

% Nominal frequency is sqrt(f1 * f2) = exp(mean([log(f1) log(f2)])).
% This is the log-domain average (works best for log chirps).

ratiofreq = sqrt(evfirst.f1 * evfirst.f2) ...
  / sqrt(evsecond.f1 * evsecond.f2);
if ratiofreq < 1
  ratiofreq = 1 / ratiofreq;
end


% Amplitude ratio should be in the range 1..inf.

if false

  % FIXME - Average amplitude didn't handle ramps very well.

  % Nominal amplitude is 0.5 * (a1 + a2).
  % This is the arithmetic mean (works best for linear ramps).
  % An endpoint misdetected as near-zero would throw off a log-domain average
  % too much.

  ratioamp = (evfirst.a1 + evfirst.a2) / (evsecond.a1 + evsecond.a2);

else

  % Nominal amplitude is the maximum amplitude.
  % This should handle ramps a bit better.

  ratioamp = max(evfirst.a1, evfirst.a2) / max(evsecond.a1, evsecond.a2);

end

if ratioamp < 1
  ratioamp = 1 / ratioamp;
end


% Length ratio should be in the range 1..inf.

ratiolen = 0;
if evfirst.duration > 0
  ratiolen = evsecond.duration / evfirst.duration;
end
if ratiolen < 1
  ratiolen = 1 / ratiolen;
end


% Overlap should be in the range 1/inf..1.
% I.e. never zero.
% In practice we're probably okay with zero as well.

fracolap = 1e-3;

if (evfirst.samprate > 0) && (evsecond.samprate > 0)

  % Get times in seconds, rather than samples.
  % The events may have different sampling rates.

  tbegfirst = evfirst.sampstart / evfirst.samprate;
  tendfirst = tbegfirst + evfirst.duration;
  tbegsecond = evsecond.sampstart / evsecond.samprate;
  tendsecond = tbegsecond + evsecond.duration;

  % Figure out the overlap.

  dursmallest = min(evfirst.duration, evsecond.duration);

  tbeglatest = max(tbegfirst, tbegsecond);
  tendearliest = min(tendfirst, tendsecond);
  durolap = tendearliest - tbeglatest;  % May be zero or negative.

  if (0 < dursmallest) && (0 < durolap)
    fracolap = durolap / dursmallest;
  end
end



% Figure out if this passes the match criteria.

ismatch = (freqratiomax >= ratiofreq) && (ampratiomax >= ratioamp) ...
  && (lenratiomax >= ratiolen) && (olapfracmin <= fracolap);


% Calculate a distance vector and distance metric.

% In a perfect world, a distance of 0 would indicate a perfect match.
% Instead, component values of 1 indicate a perfect match. Keeping them
% closer to their original forms makes them easier to interpret.

% Invert the overlap fraction, changing from 0..1 to 1..inf.
fracolap = (1 / fracolap);

% Build the vector.

dvec = [ ratiofreq, ratioamp, ratiolen, fracolap ];
cnames = { 'freq ratio', 'amp ratio', 'length ratio', '1/overlap' };

% Distance metric.
% This is magnitude / sqrt(number of components); values are in the same
% ballpark independent of the dimensionality of the vector.

distance = rms(dvec);


% Done.

end

%
% This is the end of the file.
