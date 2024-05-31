function binlist = wlFT_getTimeBinSingle()

% function binlist = wlFT_getTimeBinSingle()
%
% This generates a time bin list with a single entry of infinite extent.
% This is intended to be used for burst rate evaluations where bursts are
% not separated into time bins.
%
% No arguments.
%
% "binlist" is a cell array. Each cell contains a [ min max ] time pair
%   specifying the time bin extents in seconds.


binlist = { [ -inf inf ] };


% Done.
end


%
% This is the end of the file.
