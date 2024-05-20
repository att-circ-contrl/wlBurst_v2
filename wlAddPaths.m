function wlAddPaths

% function wlAddPaths
%
% This function detects its own path and adds appropriate child paths to
% Matlab's search path.
%
% No arguments or return value.


% Detect the current path.

fullname = which('wlAddPaths');
[ thisdir fname fext ] = fileparts(fullname);


% Add the new paths.
% Don't worry about duplicate checking; "addpath" does that for us.

addpath([ thisdir filesep 'lib-wl-aux' ]);
addpath([ thisdir filesep 'lib-wl-ft' ]);
addpath([ thisdir filesep 'lib-wl-plot' ]);
addpath([ thisdir filesep 'lib-wl-proc' ]);
addpath([ thisdir filesep 'lib-wl-synth' ]);


% Done.
end

%
% This is the end of the file.
