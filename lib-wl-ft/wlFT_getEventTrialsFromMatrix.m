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


% Figure out which context waves we have.

scratch = struct();
if (bandcount > 0) && (trialcount > 0) && (chancount > 0)
  scratch = eventmatrixdata.waves{1,1,1};
end
have_context_bpf = isfield(scratch, 'bpfwave');
have_context_ftwb = isfield(scratch, 'ftwave');

% Add the context waves to the channel list.

context_bpf_idx = NaN;
context_ftwb_idx = NaN;
if have_context_bpf
  eventftdata.label = [ eventftdata.label { 'origbpf' } ];
  context_bpf_idx = length(eventftdata.label);
end
if have_context_ftwb
  eventftdata.label = [ eventftdata.label { 'origwb' } ];
  context_ftwb_idx = length(eventftdata.label);
end


%
% Copy the events to the Field Trip data structure.


evtrialcount = 0;

auxnamelut = {};

% We need to pretend all of these fake trials came from non-overlapping
% parts of a continuous recording.
fakeoffset = 0;

for bidx = 1:bandcount

  for tidx = 1:trialcount

    for cidx = 1:chancount

      % Store trial waveforms.
      % FIXME - If this is a full copy, we can do it outside the loop.
      % We do need this in-loop to get context waveforms.

      contextwaves = eventmatrixdata.waves{bidx, tidx, cidx};
      eventftdata.wlnotes.wavesbybandandtrial{bidx, tidx, cidx} = ...
        contextwaves;


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

        % Get the span in the original trial.
        % FIXME - We might want to add a halo around this.

        sampstart = thisev.auxdata.ft_sampstart;
        sampend = thisev.auxdata.ft_sampend;

        % Add context waves from this span.

        if have_context_bpf
          eventftdata.trial{evtrialcount}(context_bpf_idx,:) = ...
            contextwaves.bpfwave(sampstart:sampend);
        end
        if have_context_ftwb
          eventftdata.trial{evtrialcount}(context_ftwb_idx,:) = ...
            contextwaves.ftwave(sampstart:sampend);
        end

        % Add sampleinfo segmentation information.
        % NOTE - We have to pretend these events came from non-overlapping
        % portions of a single continuous recording.

        sampcount = 1 + sampend - sampstart;
        eventftdata.sampleinfo(evtrialcount,:) = ...
          [ (fakeoffset + 1), (fakeoffset + sampcount) ];
        fakeoffset = fakeoffset + sampcount;

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
