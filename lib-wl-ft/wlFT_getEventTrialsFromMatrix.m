function eventftdata = wlFT_getEventTrialsFromMatrix( eventmatrixdata );

% function eventftdata = wlFT_getEventTrialsFromMatrix( eventmatrixdata );
%
% This function converts an "event matrix" structure as described by
% EVMATRIX.txt into a Field Trip data structure.
%
% "eventftdata" uses Field Trip's format, storing each detected event as a
% trial. Event metadata (including original trial/channel) goes in
% "trialinfo". An additional "wlnotes" metadata structure provides field
% information for "trialinfo", and holds metadata that isn't stored per-trial.
% This is described in "WLNOTES.txt".
%
% "eventmatrixdata" is a structure describing detected events and auxiliary
%   data, per EVMATRIX.txt.
%
% "eventftdata" is a Field Trip data structure describing detected events.


% Extract metadata.

bandlist = eventmatrixdata.bandinfo;
ftrate = eventmatrixdata.samprate;

[ bandcount trialcount chancount ] = size(eventmatrixdata.events);


% Initialize the event structure.

% NOTE - struct() requires cell arrays to be wrapped by single-cell
% cell arrays. The wrapper cell arrays are interpreted as holding an array
% of initialization values for an array of structs, rather than as an
% initialization value for a single struct. So we initialize the single
% struct as an array of 1 struct.

eventftdata = struct( 'fsample', ftrate, 'trial', {{}}, 'time', {{}}, ...
  'sampleinfo', [], 'trialinfo', [], ...
  'label', {{ 'wave', 'mag', 'freq', 'phase' }}, ...
  'wlnotes', struct() );


% Store initial metadata.

eventftdata.wlnotes.bandinfo = bandlist;
eventftdata.wlnotes.segconfigbyband = eventmatrixdata.segconfigbyband;
eventftdata.wlnotes.paramconfigbyband = eventmatrixdata.paramconfigbyband;



%
% Copy the events to the Field Trip data structure.


evtrialcount = 0;

auxnamelut = {};

for bidx = 1:bandcount

  for tidx = 1:trialcount

    for cidx = 1:chancount

      % Store trial waveforms.
      % FIXME - If this is a full copy, we can do it outside the loop.

      eventftdata.wlnotes.wavesbybandandtrial{bidx, tidx, cidx} = ...
        eventmatrixdata.waves{bidx, tidx, cidx};


      % FIXME - Discarding everything in "eventmatrixdata.auxdata".


      % Fetch events.

      events = eventmatrixdata.events{bidx, tidx, cidx};


      % Store the auxdata field names we care about.
      % NOTE - We only actually need to do this once.

      if ( 0 == length(auxnamelut) ) && ( 0 < length(events) )

        thisev = events(1);
        oldnames = fieldnames(thisev.auxdata);
        newcount = 0;

        for nidx = 1:length(oldnames)
          thisname = oldnames{nidx};
          matches = regexp(thisname, '^ft_(.*)', 'tokens');
          if 0 < length(matches)
            newcount = newcount + 1;
            auxnamelut{newcount,1} = thisname;
            % NOTE - This is returning an array of arrays, apparently.
            auxnamelut{newcount,2} = matches{1}{1};
          end
        end

        % We're not dereferencing, so use parantheses, not curly braces.
        eventftdata.wlnotes.trialinfo_label = auxnamelut(:,2);

      end


      % Store the events themselves.

      for eidx = 1:length(events)

        thisev = events(eidx);

        evtrialcount = evtrialcount + 1;

        eventftdata.time{evtrialcount} = thisev.times;

        eventftdata.trial{evtrialcount}(1,:) = thisev.wave;
        eventftdata.trial{evtrialcount}(2,:) = thisev.mag;
        eventftdata.trial{evtrialcount}(3,:) = thisev.freq;
        eventftdata.trial{evtrialcount}(4,:) = thisev.phase;

        eventftdata.sampleinfo(evtrialcount,:) = ...
          [ thisev.auxdata.ft_sampstart thisev.auxdata.ft_sampend ];

        % Copy relevant auxdata entries.
        % FIXME - Discarding non-fieldtrip auxdata entries.
        for fidx = 1:length(auxnamelut)
          eventftdata.trialinfo(evtrialcount,fidx) = ...
            getfield(thisev.auxdata, auxnamelut{fidx,1});
        end

      end

    end  % Channel iteration.

  end  % Trial iteration.

end  % Band iteration.


%
% Done.

end


%
% This is the end of the file.
