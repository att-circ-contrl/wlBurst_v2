function error = wlProc_calcWaveErrorAbsolute( ...
  bigwave, bigstart, subwave, substart)

% function error = wlProc_calcWaveErrorAbsolute( ...
%   bigwave, bigstart, subwave, substart)
%
% This function calculates the "error" between an event waveform and a
% reference waveform.
% The "Absolute" version computes this as RMS(error) without normalizing.
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

  % Compute "error" as RMS(error) without further normalization.

  error = rms(segdiff);

end


%
% Done.

end

%
% This is the end of the file.
