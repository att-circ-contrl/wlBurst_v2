function wlPlot_plotMatrixBurstRates(cfg, ...
  rate_avg, rate_dev, rate_sem, bg_avg, bg_dev, bg_sem, ...
  timebins, bandtitles, bandlabels, channelnames, ...
  figtitle, filelabel)

% function wlPlot_plotMatrixBurstRates(cfg, ...
%   rate_avg, rate_dev, rate_sem, bg_avg, bg_dev, bg_sem, ...
%   timebins, bandtitles, bandlabels, channelnames, ...
%   figtitle, filelabel)
%
% This function plots burst rate data returned by wlStats_getMatrixBurstRates.
%
% If only one time window is present, one plot per channel is generated, with
% band as the independent variable.
%
% If multiple time windows are present, multiple plots per channel are
% generated (one per band), with time as the independent variable.
%
% "cfg" contains figure configuration information (per "FIGCONFIG.txt").
% "rate_avg" contains burst rates, indexed by (bidx, cidx, widx).
% "rate_dev" contains the standard deviation of burst rates across trials.
% "rate_sem" contains the standard error of the mean of the burst rate
%   (the estimated standard deviation of the value of "rate_avg").
% "bg_avg" contains the background burst rate, indexed by (bidx, cidx, widx).
% "bg_dev" contains the standard deviation of the background rates.
% "bg_sem" contains the standard error of the mean of the background rates.
% "timebins" is a vector of length Nbins+1 containing time window edges, or
%   a vector of length Nbins containing time window midpoints, or a cell
%   array of length Nbins containing [ min max ] time ranges.
% "bandtitles" is a cell array containing human-readable plot-safe band names.
% "bandlabels" is a cell array containing filename-safe band labes.
% "channelnames" is a cell array containing raw channel names (such as
%   from Field Trip's "label" field).
% "figtitle" is the title to apply to the figure series.
% "filelabel" is used within figure filenames to identify this figure series.


% Get dimensions.
[ bandcount chancount wincount ] = size(rate_avg);


% Convert time bins to a vector of midpoints.

if iscell(timebins)
  % Convert a cell array of bin spans to a vector of midpoints.
  scratch = timebins;
  timebins = [];
  for widx = 1:wincount
    thisbin = scratch{widx};
    timebins(widx) = mean(thisbin);
  end
elseif length(timebins) > wincount
  % Convert bin edges to midpoints.
  timebins = 0.5 * ( timebins(1:wincount) + timebins(2:(wincount+1)) );
end

% Make sure this is a row vector.
timebins = reshape(timebins, 1, []);


% Convert channel names.
[ chanlabels chantitles ] = wlAux_makeSafeString( channelnames );


% Set up the palette.
colrate = [ 0.0 0.4 0.7 ];
colbg = [ 0.9 0.7 0.1 ];
colblk = [ 0 0 0 ];


%
% Make plots.

figure(cfg.fig);

for cidx = 1:chancount

  if wincount > 1

    % Plot one figure per band, with time as the independent axis.

    for bidx = 1:bandcount

      thisravg = rate_avg(bidx,cidx,:);
      thisrdev = rate_dev(bidx,cidx,:);
      thisrsem = rate_sem(bidx,cidx,:);

      thisravg = reshape(thisravg, 1, []);
      thisrdev = reshape(thisrdev, 1, []);
      thisrsem = reshape(thisrsem, 1, []);

      thisbgavg = bg_avg(bidx,cidx,:);
      thisbgdev = bg_dev(bidx,cidx,:);
      thisbgsem = bg_sem(bidx,cidx,:);

      thisbgavg = reshape(thisbgavg, 1, []);
      thisbgdev = reshape(thisbgdev, 1, []);
      thisbgsem = reshape(thisbgsem, 1, []);

      clf('reset');
      hold on;


      plot( timebins, thisravg, '-', 'Color', colrate, ...
        'DisplayName', 'burst rate' );

      plot( timebins, thisravg + thisrsem, '--', 'Color', colrate, ...
        'HandleVisibility', 'off' );
      plot( timebins, thisravg - thisrsem, '--', 'Color', colrate, ...
        'HandleVisibility', 'off' );

      plot( timebins, thisravg + thisrdev, ':', 'Color', colrate, ...
        'HandleVisibility', 'off' );
      plot( timebins, thisravg - thisrdev, ':', 'Color', colrate, ...
        'HandleVisibility', 'off' );


      plot( timebins, thisbgavg, '-', 'Color', colbg, ...
        'DisplayName', 'background' );

      plot( timebins, thisbgavg + thisbgsem, '--', 'Color', colbg, ...
        'HandleVisibility', 'off' );
      plot( timebins, thisbgavg - thisbgsem, '--', 'Color', colbg, ...
        'HandleVisibility', 'off' );

      plot( timebins, thisbgavg + thisbgdev, ':', 'Color', colbg, ...
        'HandleVisibility', 'off' );
      plot( timebins, thisbgavg - thisbgdev, ':', 'Color', colbg, ...
        'HandleVisibility', 'off' );


      plot( nan, nan, '--', 'Color', colblk, 'DisplayName', 's.e.m.' );
      plot( nan, nan, ':', 'Color', colblk, 'DisplayName', 's.d.' );


      hold off;

      legend('Location', 'northwest');
      title([ figtitle ' - ' bandtitles{bidx} ' - ' chantitles{cidx} ]);
      xlabel('Time (s)');
      ylabel('Burst Rate (per second)');

      saveas( cfg.fig, [ cfg.outdir filesep 'rates-' filelabel '-' ...
        bandlabels{bidx} '-' chanlabels{cidx} '.png' ] );


      % End of band iteration.
    end

  else

    % Only one time window.
    % Plot one figure, with band as the independent axis.

    thisravg = rate_avg(:,cidx,1);
    thisrdev = rate_dev(:,cidx,1);
    thisrsem = rate_sem(:,cidx,1);

    thisravg = reshape(thisravg, 1, []);
    thisrdev = reshape(thisrdev, 1, []);
    thisrsem = reshape(thisrsem, 1, []);

    thisbgavg = bg_avg(:,cidx,1);
    thisbgdev = bg_dev(:,cidx,1);
    thisbgsem = bg_sem(:,cidx,1);

    thisbgavg = reshape(thisbgavg, 1, []);
    thisbgdev = reshape(thisbgdev, 1, []);
    thisbgsem = reshape(thisbgsem, 1, []);

    clf('reset');
    hold on;

% FIXME - Testing different plot types.
if false

    % Line plot.

    % Implicit X axis is 1..bandcount.

    plot( thisravg, '-', 'Color', colrate, ...
      'DisplayName', 'burst rate' );

    plot( thisravg + thisrsem, '--', 'Color', colrate, ...
      'HandleVisibility', 'off' );
    plot( thisravg - thisrsem, '--', 'Color', colrate, ...
      'HandleVisibility', 'off' );

    plot( thisravg + thisrdev, ':', 'Color', colrate, ...
      'HandleVisibility', 'off' );
    plot( thisravg - thisrdev, ':', 'Color', colrate, ...
      'HandleVisibility', 'off' );


    plot( thisbgavg, '-', 'Color', colbg, ...
      'DisplayName', 'background' );

    plot( thisbgavg + thisbgsem, '--', 'Color', colbg, ...
      'HandleVisibility', 'off' );
    plot( thisbgavg - thisbgsem, '--', 'Color', colbg, ...
      'HandleVisibility', 'off' );

    plot( thisbgavg + thisbgdev, ':', 'Color', colbg, ...
      'HandleVisibility', 'off' );
    plot( thisbgavg - thisbgdev, ':', 'Color', colbg, ...
      'HandleVisibility', 'off' );


    plot( nan, nan, '--', 'Color', colblk, 'DisplayName', 's.e.m.' );
    plot( nan, nan, ':', 'Color', colblk, 'DisplayName', 's.d.' );

elseif false

    % Bar graph with error bar annotations.

    bardata = flip([ thisravg ; thisbgavg ]);

    barobjlist = bar( 1:bandcount, bardata );

    barobjlist(1).FaceColor = colrate;
    barobjlist(1).DisplayName = 'burst rate';

    barobjlist(2).FaceColor = colbg;
    barobjlist(2).DisplayName = 'background';

    % NOTE - We don't have a good way to get error bars on this.
    % We'd need to know where the bar centres are, _and_ Matlab's z-ordering
    % is iffy.

else

    % Scatter plot with error bars.

    % Implicit X axis is 1..bandcount.

    % NOTE - The line style only applies to the (nonexistent) line, not to
    % the error bars!

    errortime = 1:bandcount;

    errorbar( errortime - 0.1, thisravg, thisrsem, ...
      's', 'LineStyle', 'none', 'CapSize', 30, ...
      'Color', colrate, 'DisplayName', 'burst rate' );
    errorbar( errortime - 0.1, thisravg, thisrdev, ...
      's', 'LineStyle', 'none', 'CapSize', 15, ...
      'Color', colrate, 'HandleVisibility', 'off' );

    errorbar( errortime + 0.1, thisbgavg, thisbgsem, ...
      's', 'LineStyle', 'none', 'CapSize', 30, ...
      'Color', colbg, 'DisplayName', 'background' );
    errorbar( errortime + 0.1, thisbgavg, thisbgdev, ...
      's', 'LineStyle', 'none', 'CapSize', 15, ...
      'Color', colbg, 'HandleVisibility', 'off' );

    xlim([0 (bandcount+1)]);

%    plot( nan, nan, '--', 'Color', colblk, 'DisplayName', 's.e.m.' );
%    plot( nan, nan, ':', 'Color', colblk, 'DisplayName', 's.d.' );

% FIXME - The right way to plot this is probably a box chart.

end


    hold off;

    legend('Location', 'northwest');
    title([ figtitle ' - ' chantitles{cidx} ]);
    xlabel('Frequency Band');
    ylabel('Burst Rate (per second)');

    % Use band names as the tick labels.
    set( gca, 'XTick', 1:bandcount, 'XTickLabel', bandtitles );

    saveas( cfg.fig, [ cfg.outdir filesep 'rates-' filelabel '-byband-' ...
      chanlabels{cidx} '.png' ] );

  end

  % End of channel iteration.
end


% Done.

end


%
% This is the end of the file.
