function wave = wlProc_calcCosineWindow(s2, s3, s4)

% function wave = wlProc_calcCosineWindow(s2, s3, s4)
%
% This function generates a cosine roll-off window with the two roll-off
% lengths independent of each other.
%
% This returns a [1xN] array of samples in the range 0..1.
%
% wave(1) is 0.
% wave(s2) is the first sample with a value of 1.
% wave(s3) is the last sample with a value of 1.
% wave(s4) is 0.
%
% If (s2-1) = (s4-s3), the result is a Tukey window (symmetrical roll-off).
% If s2 = s3 and (s2-1) = (s4-s3), the result is a von Hann window (cosine).

%
% Force sanity.

if s2 < 1
  s2 = 1;
end

if s3 < s2
  s3 = s2;
end

if s4 < s3
  s4 = s3;
end


%
% Construct the output wave.

wave = ones(1,s4);

if s2 > 1

  tinc = pi / (s2 - 1);
  theta = 1:s2;
  theta = (theta - 1) * tinc;

  wave(1:s2) = 0.5 - 0.5 * cos(theta);

end

if s4 > s3

  tinc = pi / (s4 - s3);
  theta = s3:s4;
  theta = (theta - s3) * tinc;

  wave(s3:s4) = 0.5 + 0.5 * cos(theta);

end


%
% Done.

%
% This is the end of the file.
