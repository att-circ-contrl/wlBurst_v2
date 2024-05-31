function dbvals = wlAux_sigmaTodB( sigmavals )

% function dbvals = wlAux_sigmaTodB( sigmavals )
%
% This converts multiple-of-standard-deviation threshold values into decibel
% power threshold values.
%
% "sigmavals" is a vector or matrix with standard deviation thresholds.
%
% "dbvals" is a vector or matrix with corresponding decibel thresholds.

dbvals = 20 * log10(sigmavals);

% Done.

end

%
% This is the end of the file.
