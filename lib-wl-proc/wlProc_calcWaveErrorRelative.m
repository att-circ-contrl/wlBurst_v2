function error = wlProc_calcWaveErrorRelative( ...
  bigwave, bigstart, subwave, substart)

% function error = wlProc_calcWaveErrorRelative( ...
%   bigwave, bigstart, subwave, substart)
%
% This function calculates the "error" between an event waveform and a
% reference waveform.
% The "Relative" version computes this as RMS(error) / RMS(reference).
%
% "bigwave" contains reference waveform samples.
% "bigstart" is the sample index of the alignment point within "bigwave".
% "subwave" contains the event waveform samples.
% "substart" is the sample index of the alignment point within "subwave".
%
% "error" is a non-negative real value.


% Pick a safe fallback.

error = inf;


% Handle clipped and non-overlapping cases gracefully.

startsmall = 1;
endsmall = length(subwave);

startbig = bigstart + startsmall - substart;
endbig = startbig + endsmall - startsmall;

if 1 > startbig
  diff = 1 - startbig;
  startbig = startbig + diff;
  startsmall = startsmall + diff;
end

if length(bigwave) < endbig
  diff = endbig - length(bigwave);
  endbig = endbig - diff;
  endsmall = endsmall - diff;
end


% Compute the error if things look good.

if endbig >= startbig

  segsmall = subwave(startsmall:endsmall);
  segbig = bigwave(startbig:endbig);

  segdiff = segsmall - segbig;

  % Compute "error" as RMS(error) / RMS(reference signal).

  bigpower = rms(segbig);
  errpower = rms(segdiff);

  error = inf;
  if 1.0e-12 < bigpower
    error = errpower / bigpower;
  end

end


%
% Done.

end

%
% This is the end of the file.
