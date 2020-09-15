function wlPlot_plotEventsAgainstWideband(cfg, evlist, evstride, ...
  samprate, timestamps, bpfwave, widewave, figtitle, filelabel)

% function wlPlot_plotEventsAgainstWideband(cfg, evlist, evstride, ...
%   samprate, timestamps, bpfwave, widewave, figtitle, filelabel)
%
% This function plots a series of events, showing the reconstructed signal's
% waveform against the band-pass-filtered and wideband original signals. A
% spectrogram of the wideband signal is also provided.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "evlist" is a list of event records, in the form used by traceAddBursts().
% "evstride" suppresses plots; one out of every "evstride" events is plotted.
% "samprate" is the number of samples per second in signal and event data.
% "timestamps" is the time series for signal samples.
% "bpfwave" contains band-pass-filtered signal samples.
% "widewave" contains wideband signal samples.
% "figtitle" is the title to apply to the figure. Subfigures have a prefix
%   prepended to this title.
% "filelabel" is used within the figure filename to identify this figure.


%
% Initialize.


colconsig = [ 0.0 0.4 0.7 ];
colconenv = [ 0.8 0.4 0.1 ];
colevsig = [ 0.9 0.7 0.1 ];
colevenv = [ 0.5 0.2 0.5 ];


% Compute timestamps.
if false
  alltimes = 1:length(bpfwave);
  alltimes = alltimes / samprate;
else
  alltimes = timestamps;
end


%
% Render the figure.


figure(cfg.fig);
clf('reset');

subplot(3,1,1);

hold on;

plot( alltimes, bpfwave, 'Color', colconsig );
% NOTE - Maybe we do want the analytic magnitude too?
%plot( alltimes, signal.mag, 'Color', colconenv );

for eidx = 1:evstride:length(evlist)

  thisev = evlist(eidx);

  % Make this compatible with out-of-range sampstart values.
  tofs = alltimes(1) + (thisev.sampstart - 1) / samprate;

  plot( thisev.times + tofs, thisev.wave, 'Color', colevsig );
  plot( thisev.times + tofs, thisev.mag, 'Color', colevenv );

end

hold off

set(gca, 'Box', 'on');

title(sprintf('Band-Pass - %s', figtitle));
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');


subplot(3,1,2);

hold on;

plot( alltimes, widewave, 'Color', colconsig );

for eidx = 1:evstride:length(evlist)

  thisev = evlist(eidx);

  % Make this compatible with out-of-range sampstart values.
  tofs = alltimes(1) + (thisev.sampstart - 1) / samprate;

  plot( thisev.times + tofs, thisev.wave, 'Color', colevsig );
  plot( thisev.times + tofs, thisev.mag, 'Color', colevenv );

end

hold off

set(gca, 'Box', 'on');

title(sprintf('Wideband - %s', figtitle));
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');


subplot(3,1,3);

hold on;

% NOTE - Pass timestamp array, not sampling rate, to pspectrum.
pspectrum( widewave, alltimes, 'spectrogram', ...
  'FrequencyResolution', cfg.psfres, 'OverlapPercent', cfg.psolap, ...
  'Leakage', cfg.psleak, 'Minthreshold', -60, ...
  'FrequencyLimits', [ 0 cfg.psylim ] );
ylim([ 0 cfg.psylim ]);


% Scatter-plot events on top of the power spectrum.
% NOTE - We want to flag ones of different intensity, so make multiple passes.

% First pass: Get the thresholds for intensity.

maxamp = 0;
for eidx = 1:length(evlist)
  thisev = evlist(eidx);
  maxamp = max(maxamp, thisev.a1);
  maxamp = max(maxamp, thisev.a2);
end


% Second pass: split into intensity-based lists.

%scatterthresh = [ 0, 0.05 * maxamp, 0.2 * maxamp ];  % Amplitude.
scatterthresh = [ -inf, -6, 6 ];  % dB.
scattercols{1} = [0.2, 0.7, 0.2];
scattercols{2} = [0.1, 0.4, 0.5];
scattercols{3} = [0.5, 0.2, 0.5];

thislist = ...
  struct( 'xavg', [], 'yavg', [], 'xrad', [], 'yrad', [], 'ptcount', 0 );

for lidx = 1:length(scatterthresh)
  scatterlist(lidx) = thislist;
end

% Respect "event stride" when doing the sorting.
for eidx = 1:evstride:length(evlist)

  thisev = evlist(eidx);

  % Get the amplitude bin.

  lidx = 0;
%  thisamp = max(thisev.a1, thisev.a2);
  thisamp = thisev.snr;
  for ltest = 1:length(scatterthresh)
    if thisamp >= scatterthresh(ltest)
      lidx = ltest;
    end
  end

  % Get event statistics.

  % Make this compatible with out-of-range sampstart values.
  tstart = alltimes(1) + (thisev.sampstart - 1) / samprate;
  tend = tstart + thisev.duration;

  xavg = 0.5 * (tstart + tend);
  xrad = 0.5 * thisev.duration;

  yavg = 0.5 * (thisev.f1 + thisev.f2);
  yrad = abs(thisev.f2 - yavg);

  % Add this event to the appropriate list.

  thislist = scatterlist(lidx);

  ptcount = thislist.ptcount + 1;
  thislist.ptcount = ptcount;

  thislist.xavg(ptcount) = xavg;
  thislist.xrad(ptcount) = xrad;
  thislist.yavg(ptcount) = yavg;
  thislist.yrad(ptcount) = yrad;

  scatterlist(lidx) = thislist;
end


% Third pass: Plot the different event lists.

% FIXME - Check to see if we're using "minutes" or other such units, and
% scale appropriately.

limits_axis = xlim;
delta_axis = max(limits_axis) - min(limits_axis);
delta_wave = max(alltimes) - min(alltimes);
delta_ratio = delta_wave / delta_axis;

timefactor = 1.0;
if (delta_ratio > 20) && (delta_ratio < 200)
  % Assume "minutes".
  timefactor = 1 / 60.0;
elseif (delta_ratio > 1000) && (delta_ratio < 10000)
  % Assume "hours".
  timefactor = 1 / 3600.0;
elseif (delta_ratio < 0.01) && (delta_ratio > 0.0001)
  % Assume "milliseconds".
  timefactor = 1000.0;
end

% Plot the events.

for lidx = 1:length(scatterlist)

  thislist = scatterlist(lidx);
  errorbar( thislist.xavg * timefactor, thislist.yavg, ...
    thislist.yrad, thislist.yrad, ...
    thislist.xrad * timefactor, thislist.xrad * timefactor, ...
    'o', 'Color', scattercols{lidx}, 'HandleVisibility', 'off' );

end


hold off

%set(gca, 'Box', 'on');

title(sprintf('Spectrum - %s', figtitle));


%
% Save the figure.


saveas(cfg.fig, sprintf('%s/commonwb-%s.png', cfg.outdir, filelabel));


%
% Done.

end  % Function.

%
% This is the end of the file.
