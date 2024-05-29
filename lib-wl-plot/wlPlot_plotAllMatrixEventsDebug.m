function wlPlot_plotAllMatrixEventsDebug(cfg, evmatrix, ...
  figtitle, figlabel, plotsperband, trialstride, channelstride, eventstride)

% function wlPlot_plotAllMatrixEventsDebug(cfg, evmatrix, ...
%   figtitle, figlabel, plotsperband, trialstride, channelstride, eventstride)
%
% This function plots all or some of the events in an "event matrix", such
% as that returned by wlFT_doFindEventsInTrial_MT(). Reconstructed events are
% plotted individually against band-pass-filtered and wideband waveforms,
% with detection diagnostic waveforms added.
%
% "cfg" contains figure configuration information (per "FIGCONFIG.txt").
% Certain plot parameters may be overridden.
% "evmatrix" is a structure describing detected events and auxiliary data,
% (per "EVMATRIX.txt").
% "figtitle" is the title to apply to the figure series. Subfigures have a
% prefix prepended to this title.
% "figlabel" is used within figure filenames to identify this figure series.
% "plotsperband" suppresses plots; a maximum of "plotsperband" figures is
% generated per frequency band. This argument is optional.
% "trialstride" suppresses plots; one out of every "trialstride" trials has
% events plotted. This argument is optional.
% "channelstride" suppresses plots; one out of every "channelstride" channels
% has events plotted. This argument is optional.
% "eventstride" suppresses plots; one out of every "eventstride" events is
% plotted. This argument is optional.


% FIXME - This is a cut-and-paste kludge! Merge common code.


% Get iteration extents.

[ bandcount trialcount chancount ] = size(evmatrix.events);


% Set default strides and plot cap if not already set.

if ~exist('plotsperband', 'var')
  plotsperband = inf;
end

if ~exist('trialstride', 'var')
  trialstride = 1;
end

if ~exist('channelstride', 'var')
  channelstride = 1;
end

if ~exist('eventstride', 'var')
  eventstride = 1;
end


% FIXME - Magic values.

contextlengths = 1.0;
contextcycles = 3.0;


%
% Do plotting.

% Iterate bands.

for bidx = 1:bandcount

  % Initialize per-band plot count.

  pcount = 0;


  % Get additional metadata.

  thisband = evmatrix.bandinfo(bidx).band;
  bandlabel = evmatrix.bandinfo(bidx).label;
  bandname = evmatrix.bandinfo(bidx).name;

  fnom = sqrt(min(thisband) * max(thisband));

  % Tweak this for reasonable time/frequency trade-offs for theta and alpha.
%  cfg.psfres = 5;
  cfg.psfres = min(6, fnom / 3.0);

  cfg.psylim = round(1.5 * max(thisband));


  % Render events in this band.

  for tidx = 1:trialstride:trialcount
    for cidx = 1:channelstride:chancount

      % Get the event list and context for this band/trial/channel.

      evlist = evmatrix.events{bidx, tidx, cidx};
      waves = evmatrix.waves{bidx, tidx, cidx};


      % FIXME - If we don't have BPF waveforms, use the raw FT ones.
      if ~isfield(waves, 'bpfwave')
        waves.bpfwave = waves.ftwave;
        % FIXME - Not handling Hilbert signals.
      end


      % FIXME - If we don't have reconstructed event waveforms, make them.
      if 0 < length(evlist)
        if ~isfield(evlist(1), 'wave')
          evlist = wlAux_getReconFromParams(evlist);
        end
      end


      % Generate plots, if we aren't over the cap.

      if pcount < plotsperband

        % First plot series: Detected events in context.

        pcount = pcount + length(evlist);

        contextwaves = struct( ...
          'wave',  waves.bpfwave, ...
          'mag',   waves.bpfmag, ...
          'freq',  waves.bpffreq, ...
          'phase', waves.bpfphase );

        thistitle = sprintf('%s - Tr %04d - Ch %04d - %s', ...
          figtitle, tidx, cidx, bandname);
        thislabel = sprintf('%s-tr%04d-ch%04d-%s', ...
          figlabel, tidx, cidx, bandlabel);

        wlPlot_plotEventsWithContext( cfg, ...
          evlist, eventstride, contextwaves, evmatrix.samprate, ...
          fnom, contextlengths, contextcycles, ...
          thistitle, [ thislabel '-ev' ] );


        % Second plot series: Events against the trial waveform with
        % detection thresholds.

        wlPlot_plotEventsAgainstTrialDebug( cfg, ...
          evlist, evmatrix.samprate, waves, ...
          thistitle, [ thislabel '-th' ] );

      end  % Plot count check.

    end  % Channel iteration.
  end  % Trial iteration.
end  % Band iteration.



%
% Done.

end

%
% This is the end of the file.
