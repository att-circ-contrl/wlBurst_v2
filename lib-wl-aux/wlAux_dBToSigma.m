function sigmavals = wlAux_dBtoSigma( dbvals )

% function sigmavals = wlAux_dBtoSigma( dbvals )
%
% This converts decibel power threshold values into multiple-of-standard-
% -deviation threshold values.
%
% "dbvals" is a vector or matrix with decibel thresholds.
%
% "sigmavals" is a vector or matrix with corresponding standard deviation
%   thresholds.

sigmavals = 10.^(dbvals / 20);

% Done.

end

%
% This is the end of the file.
