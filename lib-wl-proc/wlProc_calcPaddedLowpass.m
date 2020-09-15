function newdata = wlProc_calcPaddedLowpass(olddata, fcorner, samprate)

% function newdata = wlProc_calcPaddedLowpass(olddata, fcorner, samprate)
%
% This function wraps Matlab's "lowpass" function.
% Zero-padding is added on both sides of the data to give Matlab's filters
% time to stabilize. This is removed when the trace is returned.
% There will still be artifacts, but amplitude should be much lower than
% calling "lowpass" directly.
%
% "olddata" is the signal to filter.
% "fcorner" is the filter's cutoff frequency.
% "samprate" is the number of samples per second in the signal data.
%
% "newdata" is the filtered signal.


% Figure out appropriate lengths.

oldlength = length(olddata);
padlength = round(20 * samprate / fcorner);


% Construct the padded trace.

tempdata(1:padlength) = 0;
tempdata( (padlength+1):(padlength+oldlength) ) = olddata;
tempdata( (padlength+oldlength+1):(padlength+oldlength+padlength) ) = 0;


% Filter the padded trace and return the trimmed version.

tempdata = lowpass(tempdata, fcorner, samprate);

newdata = tempdata( (padlength+1):(padlength+oldlength) );


% Done.

end

%
% This is the end of the file.
