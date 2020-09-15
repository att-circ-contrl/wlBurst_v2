function paramstr = wlAux_getStringFromParams(thisev)

% function paramstr = wlAux_getStringFromParams(thisev)
%
% This function builds a human-readable text string describing the fit
% parameters in the specified event record.
%
% "thisev" is the event structure to describe, per EVENTFORMAT.txt.
%
% "paramstr" is the text representation of the event parameters.


paramstr = '-- bogus --';


% Switch based on the type of parametric description.

if strcmp('chirpramp', thisev.paramtype)

  paramstr = sprintf( ...
    'Duration / Roll-on / Roll-off:   %.3f   %.3f   %.3f', ...
    thisev.duration, thisev.rollon, thisev.rolloff );

  paramstr = [ paramstr ...
    sprintf('\nGlobal position:  Sample %d  (%d / second)', ...
      thisev.sampstart, thisev.samprate) ];

  if isfield(thisev, 's1') && isfield(thisev, 's2') ...
    && isfield(thisev, 'wave')
    paramstr = [ paramstr ...
      sprintf( ...
        '\nRange in stored wave:  %d .. %d  (%d)  (t = %.4f .. %.4f)', ...
        thisev.s1, thisev.s2, length(thisev.wave), ...
        thisev.times(thisev.s1), thisev.times(thisev.s2) ) ];
  end

  paramstr = [ paramstr sprintf('\nAmplitude:  %.3f .. %.3f  (%s)', ...
    thisev.a1, thisev.a2, thisev.atype) ];

  paramstr = [ paramstr sprintf('\nFrequency:  %.3f .. %.3f  (%s)', ...
    thisev.f1, thisev.f2, thisev.ftype) ];

  paramstr = [ paramstr sprintf('\nPhase:  %.3f .. %.3f', ...
    thisev.p1, thisev.p2) ];

else
  disp(sprintf( ...
    '### [wlAux_getStringFromParams]  Unrecognized type "%s".', ...
    thisev.paramtype ));
end


%
% Done.

end


%
% This is the end of the file.
