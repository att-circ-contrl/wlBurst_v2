function newdata = wlProc_calcPaddedBandpass(olddata, band, samprate)

% function newdata = wlProc_calcPaddedBandpass(olddata, band, samprate)
%
% This function wraps Matlab's "bandpass" function.
% Zero-padding is added on both sides of the data to give Matlab's filters
% time to stabilize. This is removed when the trace is returned.
% There will still be artifacts, but amplitude should be much lower than
% calling "bandpass" directly.
%
% "olddata" is the signal to filter.
% "band" [ min max ] is the frequency band to pass.
% "samprate" is the number of samples per second in the signal data.
%
% "newdata" is the filtered signal.


% Figure out appropriate lengths.
% Use min(band) instead of band(1), just in case the user swapped the order.

oldlength = length(olddata);
padlength = round(20 * samprate / min(band));


% Construct the padded trace.

tempdata(1:padlength) = 0;
tempdata( (padlength+1):(padlength+oldlength) ) = olddata;
tempdata( (padlength+oldlength+1):(padlength+oldlength+padlength) ) = 0;


% Filter the padded trace and return the trimmed version.

tempdata = bandpass(tempdata, band, samprate);

newdata = tempdata( (padlength+1):(padlength+oldlength) );


% Done.

end

%
% This is the end of the file.
