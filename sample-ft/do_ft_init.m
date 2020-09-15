% Field Trip-related test scripts - Initialization.

% Paths.

addpath('lib-wl-synth');
addpath('lib-wl-proc');
addpath('lib-wl-ft');
addpath('lib-wl-aux');
addpath('lib-wl-plot');


% Colours.
% Mostly cribbed from get(gca,'colororder') (the defaults).

cblu = [ 0.0 0.4 0.7 ];
cbrn = [ 0.8 0.4 0.1 ]; % Tweaked; original was [ 0.9 0.3 0.1 ].
cyel = [ 0.9 0.7 0.1 ];
cmag = [ 0.5 0.2 0.5 ];
cgrn = [ 0.5 0.7 0.2 ];
ccyn = [ 0.3 0.7 0.9 ];
cred = [ 0.6 0.1 0.2 ];


%
% Signal information.

datadir = 'data';

fsamp = 1000;

bandwide = [ 1 400 ];

bandtheta = [ 4 7.5 ];
bandalpha = [ 7.5 12.5 ];
bandbeta = [ 12.5 30 ];
bandgammalo = [ 30 60 ];
bandgammahi = [ 60 100 ];

bandgamma = [ bandgammalo(1) bandgammahi(2) ];

bandlist = [ ...
  struct('band', bandtheta,   'label', 'th', 'name', 'Theta') ...
  struct('band', bandalpha,   'label', 'al', 'name', 'Alpha') ...
  struct('band', bandbeta,    'label', 'be', 'name', 'Beta') ...
  struct('band', bandgammalo, 'label', 'gl', 'name', 'Gamma (Low)') ...
  struct('band', bandgammahi, 'label', 'gh', 'name', 'Gamma (high)') ];

bandlistbands = { bandtheta, bandalpha, bandbeta, bandgammalo, bandgammahi };

bandlistwide = ...
  [ struct('band', bandwide, 'label', 'wb', 'name', 'Wideband') ];


%
% Synthetic Field Trip data parameters.

synth_use_small_dataset = false;

% NOTE - This switch affects filenames too, so that both versions can be
% saved/loaded as needed.
synth_use_one_trial = false;


synth_trialcount = 20;
synth_chancount = 16;

% FIXME - Short trials have pretty bad edge artifacts.
%synth_trialdur = [ 3 5 ];
synth_trialdur = [ 5 8 ];

if synth_use_small_dataset
  % FIXME - Use a smaller set for testing.
  synth_trialcount = 10;
  synth_chancount = 4;
end

synth_channelratevar = [ 0.1 1.0 ];
synth_channelnoisevar = [ -10 10 ];

synth_fname_data = sprintf('%s/ftsynth.mat', datadir);
synth_fname_detect = sprintf('%s/ftsynthdetect.mat', datadir);

if synth_use_one_trial

  synth_trialdur = synth_trialdur * synth_trialcount;
  synth_trialcount = 1;

  synth_fname_data = sprintf('%s/ftsynth-long.mat', datadir);
  synth_fname_detect = sprintf('%s/ftsynthdetect-long.mat', datadir);

end


%
% Default event segmentation information.

% Frequency-based detection: add noise and look for flat analytic frequency.

segbandnoise = [ 200 400 ];
segnoisesnrchosen = 10;  % Fixed noise SNR for frequency-based detection.

% NOTE - Making the "ac" time constant longer requires making the dropout
% period longer as well, as dropout timescale is set by smoothing time.

segfreqvarqlong = 10;  % Number of mid-frequency periods for "dc" filtering.
segfreqvarqshort = 0.25;  % Number of mid-frequency periods for "ac" smoothing.

segfreqglitchq = 1.0;  % Events shorter than this many periods are dropped.
segfreqdropoutq = 0.5;  % Gaps shorter than this many periods are ignored.


% Amplitude-based detection: threshold the BPF analytic magnitude.

segmagvarqlong = 10;  % Number of mid-frequency periods for "dc" filtering.

segmagglitchq = 1.0;  % Events shorter than this many periods are dropped.
segmagdropoutq = 0.5;  % Gaps shorter than this many periods are ignored.


% Detection threshold sweep information.
% Thresholds are in dB, comparing a quantity to its quasi-DC average.
% For magnitude detection, it's analytic magnitude; for frequency detection,
% it's the approximate variance of the analytic frequency.

% Endpoint-detection thresholds.
% Event-detection thresholds should exceed this.
segdetendthresh = 2;

% dB. Ratio of threshold vs average magnitude power.
segdetsweepspan = [ 4 20 ];

% Interval for sweeping detection thresholds.
segdetsweepstep = 1;

% Actual detection threshold sweep values.
% Starting value and step size are guaranteed. Last value will be less than
% or equal to the specified maximum.

detsweepthresholds = segdetsweepspan(1):segdetsweepstep:segdetsweepspan(2);


% Pre-chosen detection threshold values.
% NOTE - These should map to valid values in det(mag/freq)thresholds.

% Criteria for choosing "good" threshold values.
eventerrmax = 0.3;

% Hardcoded values; these can be overridden.

if synth_use_one_trial

  % Long-trace versions, with "RMS error <= 0.7" pruning.
  magthreshdb =  [ 10 12 12  8 10 ];
  freqthreshdb = [  8  8 10 10 14 ];

else

  % Short-trace versions, with "RMS error <= 0.7" pruning.
  magthreshdb =  [  8 16 12 12 10 ];
  freqthreshdb = [  2  6  6 10 12 ];

end


% Threshold range for plotting.
% These are relative to the chosen "good" thresholds.
% NOTE - If the middle value _isn't_ zero, we need to tweak thresholds.
plotthreshdbmag =  [ -4 0 4 ];
plotthreshdbfreq = [ -2 0 2 ];
plotthreshcolors = { cyel cbrn cblu };
plotthreshnames = { 'low', 'medium', 'high' };



% Ground truth matching parameters.

matchfreq = 1.5;    % Worst-case frequency ratio.
matchamp = 3.0;     % Worst-case amplitude ratio.
matchlength = 4.0;  % Worst-case length ratio.
matcholap = 0.75;   % Worst-case overlap fraction.

% Event binning for ground truth matching.

eventbintime = 5;    % Seconds per bin.
eventbinsearch = 1;  % Bins to search on either side for matches.

% Lambda function for match comparison.
evcomparefunc = @(evfirst, evsecond) ...
  wlProc_calcMatchFromParams(evfirst, evsecond, ...
    matchfreq, matchamp, matchlength, matcholap);

% Lambda function for "never match".
evcomparefuncfalse = @(evfirst, evsecond) deal(false, inf);

% Lambda function for "match only if really close".
% This is intended for merging events that were duplicated.
evcomparefuncdup = @(evfirst, evsecond) ...
  wlProc_calcMatchFromParams(evfirst, evsecond, ...
    matchfreq^0.2, matchamp^0.2, matchlength^0.2, matcholap^0.2);



%
% Curve-fitting information.

% Simulated annealing parameters.
annealmaxtries = 100;
%annealmaxtotal = 1000;
% NOTE - It takes about 10,000 steps for things to look really good.
annealmaxtotal = 10000;


%
% Figure information.

outdir = 'output';
scratchfig = figure;


% Context window around detected bursts.
% It's the greater of N cycles or N times the burst length on each side.
contextcycles = 4.0;
contextlengths = 2.0;


% Figure configuration structure.

figconfig.fig = scratchfig;
figconfig.outdir = outdir;

% Power spectrum parameters.
% NOTE - This is sensitive to the band we're looking at. These defaults
% are tolerable most of the time.
figconfig.fsamp = fsamp;
figconfig.psfres = 5;
figconfig.psolap = 99;
figconfig.psleak = 0.75;
figconfig.psylim = 50;


% Turn certain plot subsets on or off.

% Plot every Nth event.
eventstride = 25;

% Only emit the first K plots for any given band.
eventplotsperband = 4;

% Event matrix plotting configuration.

%bandplots_max = eventplotsperband;
bandplots_max = inf;

%stride_trial = eventstride;
stride_trial = 1;

stride_channel = 1;


%
% Reload data.


% Synthetic waveforms and ground truth.

if isfile(synth_fname_data) && (~exist('traceft', 'var'))
  disp('-- Loading synthetic FT data.');
  % Load everything; only relevant structures should be present.
  load(synth_fname_data);
  disp('-- Finished loading.');
end


% Detection results for synthetic events.

if isfile(synth_fname_detect) && (~exist('detectft_mag', 'var'))
  disp('-- Loading synthetic FT detection results.');
  % Load everything; only relevant structures should be present.
  load(synth_fname_detect);
  disp('-- Finished loading.');
end


%
% This is the end of the file.
