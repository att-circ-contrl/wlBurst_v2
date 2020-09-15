function newdata = wlProc_calcShortLowpass(olddata, fcorner, samprate, fact)

% function newdata = wlProc_calcShortLowpass(olddata, fcorner, samprate, fact)
%
% This function implements low-pass filtering using raised cosine windows
% as FIR filters. The farthest any disturbance can propagate is the width
% of the window.
%
% Mathematically we're convolving by an anti-aliasing filter, decimating,
% and then convolving by a reconstruction filter, where the AA and recon
% filters are raised cosine windows. The radius of the window is an
% integer multiple of the decimation sample spacing.
%
% "olddata" is the signal to filter.
% "fcorner" is the filter's cutoff frequency.
% "samprate" is the number of samples per second in the signal data.
% "fact" is a positive integer. The Nyquist frequency of the decimated
%   signal is "fact" times the corner frequency.
%
% Calculations are performed in the time domain, so this will be slow for
% "fact" >> 1. We don't actually convolve, so for small "fact" it's efficient.
% Filter slope isn't very steep so aliasing and leakage are concerns.
%
% "newdata" is the filtered signal.


% Figure out our decimation spacing and filter size in samples.
% At the corner frequency, the filter's full width is one period.

% Get first-pass filter radius. Leave this as floating-point for now.
filtrad = 0.5 * samprate / fcorner;

% Calculate decimation pitch. Make sure pitch is an integer.
decimpitch = round(filtrad / fact);
decimpitch = max(1, decimpitch);

% Make filter radius an exact multiple of pitch (and an integer).
filtrad = fact * decimpitch;


% Pad the signal by the filter radius.
% We'll get roll-on and roll-off fading propagating that far, but we're
% going to have edge artifacts of some kind no matter what.

origlength = length(olddata);

tempdata(1:filtrad) = 0;
tempdata( (filtrad+1):(filtrad+origlength) ) = olddata;
tempdata( (filtrad+origlength+1):(filtrad+origlength+filtrad) ) = 0;


% Build a cosine window of our desired size. This saves a lot of repetition.
% The middle sample's index is 1+filtrad.
coswindow = 0.5 + 0.5 * cos( (-filtrad:filtrad) * pi / filtrad );
cossum = sum(coswindow);


% Walk through the signal, building the decimated signal and the reconstructed
% signal.
% The decimated signal is computed by taking a weighted average around the
% decimation point. It's equivalent to convolving and then decimating, but
% much faster than time-domain convolution.
% The reconstructed signal is computed by adding a weighted copy of the
% window for every decimated point. It's equivalent to convolving but we skip
% all points that are zero.

recondata = zeros(size(tempdata));

dcount = origlength / decimpitch;

for didx = 1:dcount

  % Figure out where we are.
  % Sample 1 of the original signal is our first decimation point.
  dpos = 1 + filtrad + decimpitch * (didx - 1);
  posrange = (dpos-filtrad):(dpos+filtrad);

  % Get this decimated sample.
  segmentdata = tempdata(posrange);
  thissamp = sum(coswindow .* segmentdata) / cossum;

  % Add a weighted copy of the reconstruction FIR to the output.
  % We're overlapping "fact" copies, so divide by that during reconstruction.
  recondata(posrange) = recondata(posrange) + coswindow * thissamp/fact;

end


% Trim the padding and return the resulting trace.
newdata = recondata( (filtrad+1):(filtrad+origlength) );


%
% Done.

end

%
% This is the end of the file.
