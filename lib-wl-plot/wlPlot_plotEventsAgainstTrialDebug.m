function wlPlot_plotEventsAgainstTrialDebug(cfg, evlist, samprate, ...
  wavelist, figtitle, filelabel)

% function wlPlot_plotEventsAgainstTrialDebug(cfg, evlist, samprate, ...
%   wavelist, figtitle, filelabel)
%
% This function plots a series of events, showing the reconstructed signal's
% waveform against the band-pass-filtered and wideband original signals.
% Detection threshold curves are also provided where present.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "evlist" is a list of event records, in the form used by traceAddBursts().
% "samprate" is the number of samples per second in signal and event data.
% "wavelist" is a copy of the event matrix structure's "wave" structure.
%   We look for "bpfwave", "bpfmag", "ftwave", and "fttimes" for signals,
%   "magpowerfast" and "magpowerslow" for magnitude-based detection, and
%   "fvarfast" and "fvarslow" for frequency-based detection.
% "figtitle" is the title to apply to the figure. Subfigures have a prefix
%   prepended to this title.
% "filelabel" is used within the figure filename to identify this figure.


% FIXME - This is a cut-and-paste kludge! Merge common bits.

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
  alltimes = wavelist.fttimes;
end


% Extract waves.

widewave = wavelist.ftwave;
bpfwave = wavelist.bpfwave;
magwave = wavelist.bpfmag;

detectslow = nan(size(alltimes));
detectfast = nan(size(alltimes));
detectfeature = nan(size(alltimes));

if isfield( wavelist, 'magpowerfast' )
  detectslow = wavelist.magpowerslow;
  detectfast = wavelist.magpowerfast;
  detectfeature = magwave .* magwave;
elseif isfield( wavelist, 'fvarfast' )
  detectslow = wavelist.fvarslow;
  detectfast = wavelist.fvarfast;
  detectfeature = wavelist.noisyfreq;
end


%
% Render the figure.


figure(cfg.fig);
clf('reset');

subplot(3,1,1);

hold on;

plot( alltimes, widewave, 'Color', colconsig );

for eidx = 1:length(evlist)

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


subplot(3,1,2);

hold on;

plot( alltimes, bpfwave, 'Color', colconsig );
% NOTE - Maybe we do want the analytic magnitude too?
plot( alltimes, magwave, 'Color', colconenv );

for eidx = 1:length(evlist)

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


subplot(3,1,3);

hold on;

plot( alltimes, detectfeature, 'Color', colconsig );
plot( alltimes, detectslow, 'Color', colconenv );
plot( alltimes, detectfast, 'Color', colevenv );

hold off

set(gca, 'Box', 'on');

title(sprintf('Detect - %s', figtitle));
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');


%
% Save the figure.


saveas(cfg.fig, sprintf('%s/commondetect-%s.png', cfg.outdir, filelabel));


%
% Done.

end  % Function.

%
% This is the end of the file.
