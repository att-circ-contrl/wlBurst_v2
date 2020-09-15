% Field Trip-related test scripts - Synthetic FT data.
%
% See LICENSE.md for distribution information.

%
%
% Includes.

do_ft_init



%
%
% Configuration.

% NOTE - This is moved to its own file, so that we can invoke it elsewhere.

do_ft_synth_config



%
%
% Generation.


%
% Make a synthetic trace, if we don't already have one.

if ~exist('traceft', 'var')
  do_ft_synth_gen
end



%
%
% Event detection.


% Do event detection, if we haven't already.

if ~exist('detectft_mag', 'var')
  do_ft_synth_detect
end



%
%
% Event post-processing.

do_ft_synth_post



%
%
% Get event results for the "chosen" threshold values.
% Get confusion matrix counts and lists.


do_ft_synth_calc



%
%
% Plotting.


do_ft_synth_plot



%
%
% This is the end of the file.
