function newevmatrix = wlFT_pruneEventsByTime(oldevmatrix, ...
  padbegin, padend)

% function newevmatrix = wlFT_pruneEventsByTime(oldevmatrix, ...
%   padbegin, padend)
%
% This function processes an event matrix structure and removes events with
% nominal starting or stopping times that are too close to the ends of the
% trials from which they were extracted.
%
% "oldevmatrix" is a structure describing detected events and auxiliary
%   data, per "EVMATRIX.txt".
% "padbegin" is the duration of the exclusion region at the start of the trial.
% "padend" is the duration of the exclusion region at the end of the trial.
%
% "newevmatrix" is an event matrix struture containing edited event lists.


% Initialize.

newevmatrix = oldevmatrix;


% Convert timing information from seconds to samples.

samprate = oldevmatrix.samprate;

padsampstart = round(padbegin * samprate);
padsampstop = round(padend * samprate);


% Iterate through trials.

[ bandcount trialcount chancount ] = size(newevmatrix.events);

for bidx = 1:bandcount
  for tidx = 1:trialcount
    for cidx = 1:chancount

      % Get the actual fenceposts.

      timeseries = oldevmatrix.waves{bidx, tidx, cidx}.fttimes;
      samptotal = length(timeseries);

      fencefirst = 1 + padsampstart;
      fencelast = samptotal - padsampstop;

      % Force sanity.
      fencefirst = min(fencefirst, samptotal);
      fencelast = max(fencelast, fencefirst);


      % Process events.

      oldevlist = newevmatrix.events{bidx, tidx, cidx};
      newevlist = [];

      evcount = length(oldevlist);

      if 0 < evcount
        newevlist = oldevlist(1:0);  % Empty array with the correct fields.
        newcount = 0;

        for eidx = 1:evcount

          thisev = oldevlist(eidx);

          % Find the 50% rise and 50% fall points.
          sampstart = thisev.sampstart;
          sampend = sampstart + round(duration * samprate);

          if (sampstart >= fencefirst) && (sampend <= fencelast)
            newcount = newcount + 1;
            newevlist(newcount) = thisev;
          end

        end  % Iterate events.

        newevmatrix.events{bidx, tidx, cidx} = newevlist;
      end  % Empty event list check.

    end  % Iterate channels.
  end  % Iterate trials.
end  % Iterate bands.


%
% Done.

end


%
% This is the end of the file.
