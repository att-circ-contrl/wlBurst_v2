function wlPlot_plotDetectCurves(cfg, tuneseries, tunelabel, ...
  dataseries, figtitle, filelabel)

% function wlPlot_plotDetectCurves(cfg, tuneseries, tunelabel, ...
%   dataseries, figtitle, filelabel)
%
% This function plots one or more accuracy-vs-tuning-parameter curves.
%
% "cfg" contains figure configuration information (see "FIGCONFIG.txt").
% "tuneseries" is an array with the independent parameter values (x axis).
% "tunelabel" is the axis label for the independent parameter.
% "dataseries" is an array of structures defining dependent data series.
% "figtitle" is the title to apply to the figure.
% "filelabel" is used within the figure filename to identify this figure.
%
% Data series definition structures contain the following fields:
% "fp" is a [1xN] array containing false-positive values.
% "fn" is a [1xN] array containing false-negative values.
% "tp" is a [1xN] array containing true-positive values.
% "color" [ r g b ] is the colour to use when plotting this series.
% "label" is a string to identify this data series with.


%
% Fractional rates.

% FIXME - Needs a second legend for detection rate (solid) and false
% positive rate (dashed).

figure(cfg.fig);
clf('reset');

hold on;

for didx = 1:length(dataseries)

  fp = dataseries(didx).fp;
  fn = dataseries(didx).fn;
  tp = dataseries(didx).tp;

  falserate = fp ./ (fp + tp);   % 1 - precision
  detectrate = tp ./ (tp + fn);  % recall

  plot( tuneseries, 100*detectrate, '-', 'Color', dataseries(didx).color, ...
    'DisplayName', dataseries(didx).label );
  plot( tuneseries, 100*falserate, '--', 'Color', dataseries(didx).color, ...
    'HandleVisibility', 'off' );

end

hold off;

xlabel(tunelabel);
ylabel('Fraction (%)');
ylim([0 100]);

legend('show');

title(sprintf('%s - Rates', figtitle));

saveas( cfg.fig, sprintf('%s/detrate-%s.png', cfg.outdir, filelabel) );


%
% Absolute counts.

% FIXME - Needs a second legend for true positivese (solid), false positives
% (dashed), and false negatives (dotted).

figure(cfg.fig);
clf('reset');

hold on;

for didx = 1:length(dataseries)

  fp = dataseries(didx).fp;
  fn = dataseries(didx).fn;
  tp = dataseries(didx).tp;

  plot( tuneseries, tp, '-', 'Color', dataseries(didx).color, ...
    'DisplayName', dataseries(didx).label );
  plot( tuneseries, fp, '--', 'Color', dataseries(didx).color, ...
    'HandleVisibility', 'off' );
  plot( tuneseries, fn, ':', 'Color', dataseries(didx).color, ...
    'HandleVisibility', 'off' );

end

hold off;

xlabel(tunelabel);
ylabel('Event Count');
ylim([0 inf]);

legend('show');

title(sprintf('%s - Counts', figtitle));

saveas( cfg.fig, sprintf('%s/detcount-%s.png', cfg.outdir, filelabel) );


%
% Done.

end

%
% This is the end of the file.
