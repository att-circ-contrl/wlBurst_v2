function haveparallel = wlAux_checkParallelToolbox

% function haveparallel = wlAux_checkParallelToolbox
%
% This function tests for the presence of the Parallel Computing Toolbox.
% That toolbox is needed for running the _MT versions of the processing
% functions.
%
% No inputs.
%
% "haveparallel" is true if the toolbox is present, false otherwise.


versioninfo = ver;
namelist = { versioninfo.Name };

haveparallel = ismember( 'Parallel Computing Toolbox', namelist );


%
% Done.

end


%
% This is the end of the file.
