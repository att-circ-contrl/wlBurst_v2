function [ events auxwaves auxdata ] = wlProc_doSegmentAndParamExtract( ...
  wavedata, samprate, bpfband, segconfig, paramconfig, wantmultithread)

% function [ events auxwaves auxdata ] = wlProc_doSegmentAndParamExtract( ...
%   wavedata, samprate, bpfband, segconfig, paramconfig, wantmultithread)
%
% This function performs event segmentation and parameter extraction on the
% specified waveform. Specific algorithms and their tuning parameters are
% selected/specified via configuration structures.
% This version defaults to single-threaded; "wantmultithreaded" selects MT.
%
% "wavedata" is the data trace to examine.
% "samprate" is the number of samples per second in the signal data.
% "bpfband" [min max] is the frequency band of interest. Edges may fade.
% "segconfig" is a structure containing configuration information for
%   event segmentation, per SEGCONFIG.txt.
% "paramconfig" is a structure containing configuration information for
%   event parameter estimation, per PARAMCONFIG.txt.
% "wantmultithread" is "true" if _MT variants of functions are to be called.
%   This parameter is optional; the default is "false" (single-threaded).
%
% "events" is an array of structures describing detected events. Format is
%   per EVENTFORMAT.txt.
% "auxwaves" is a structure containing derived waveforms. These are
%   algorithm-specific, but typically include a band-pass-filtered version
%   of the original waveform and an analytic signal derived from this.
% "auxdata" is a structure containing other algorithm-specific metadata about
%   the analysis.


%
% Initialize.

isok = true;
fnom = sqrt(bpfband(1) * bpfband(2));

if ~exist('wantmultithread', 'var')
  wantmultithread = false;
end

auxwaves = struct();
auxdata = struct();



%
% First pass: Segment.

if strcmpi('custom', segconfig.type)

  % Opaque lambda function.
  [ segevents, waves ] = segconfig.segmentfunc( ...
    wavedata, samprate, bpfband, segconfig );

elseif strcmpi('mag', segconfig.type)

  [ segevents, waves ] = wlProc_getEvSegmentsUsingMag( ...
    wavedata, samprate, bpfband, ...
    segconfig.qglitch / fnom, segconfig.qdrop / fnom, ...
    segconfig.qlong / fnom, ...
    segconfig.dbpeak );

elseif strcmpi('magdual', segconfig.type)

  [ segevents, waves ] = wlProc_getEvSegmentsUsingMagDual( ...
    wavedata, samprate, bpfband, ...
    segconfig.qglitch / fnom, segconfig.qdrop / fnom, ...
    segconfig.qlong / fnom, ...
    segconfig.dbpeak, segconfig.dbend );

elseif strcmpi('freq', segconfig.type)

  [ segevents, waves ] = wlProc_getEvSegmentsUsingFreq( ...
    wavedata, samprate, bpfband, ...
    segconfig.noiseband, segconfig.noisesnr, ...
    segconfig.qglitch / fnom, segconfig.qdrop / fnom, ...
    segconfig.qlong / fnom, segconfig.qshort / fnom, ...
    segconfig.dbpeak );

elseif strcmpi('freqdual', segconfig.type)

  [ segevents, waves ] = wlProc_getEvSegmentsUsingFreqDual( ...
    wavedata, samprate, bpfband, ...
    segconfig.noiseband, segconfig.noisesnr, ...
    segconfig.qglitch / fnom, segconfig.qdrop / fnom, ...
    segconfig.qlong / fnom, segconfig.qshort / fnom, ...
    segconfig.dbpeak, segconfig.dbend );

else

  disp(sprintf('### Unknown segmentation algorithm "%s".', segconfig.type));
  isok = false;

end


% Copy waveform data to auxwaves.
if (isok)
  auxwaves = waves;
end



%
% Second pass: Parameter extraction.

% First, figure out which steps we want to perform.

do_basic = false;
do_gridseries = false;
do_annealamp = false;
do_annealwave = false;

if ~isok

  % Do nothing; we already reported the error.

elseif strcmpi('custom', paramconfig.type)

  % Opaque lambda function.
  [ events, auxdata ] = paramconfig.paramfunc( ...
    segevents, waves, samprate, paramconfig );

elseif strcmpi('fast', paramconfig.type)

  do_basic = true;

elseif strcmpi('grid', paramconfig.type)

  do_gridseries = true;

elseif strcmpi('annealamp', paramconfig.type)

  do_gridseries = true;
  do_annealamp = true;

elseif strcmpi('annealboth', paramconfig.type)

  do_gridseries = true;
  do_annealamp = true;
  do_annealwave = true;

else

  disp(sprintf('### Unknown parameter extraction algorithm "%s".', ...
    segparam.type));
  isok = false;

end


% Now that we know what to do, call single- or multi-threaded implementations.

if do_basic

  % Estimate parameters without a grid search.

  events = wlProc_getEvParamsUsingHilbert( waves.bpfwave, samprate, ...
    waves.bpfmag, waves.bpffreq, waves.bpfphase, segevents, NaN );

elseif do_gridseries

  % Use a grid search, and optionally anneal after the search.

  events = wlProc_getEvParamsUsingHilbert( waves.bpfwave, samprate, ...
    waves.bpfmag, waves.bpffreq, waves.bpfphase, segevents, ...
    paramconfig.gridsteps );


  % Set up the match evaluation helper.

  if do_annealamp || do_annealwave
    comparefunc = @(evfirst, evsecond) ...
      wlProc_calcMatchFromParams( evfirst, evsecond, ...
        paramconfig.matchfreq, paramconfig.matchamp, ...
        paramconfig.matchlength, paramconfig.matcholap );
  end


  % Fine-tune the envelope fit if desired.

  if do_annealamp

    if wantmultithread
      [ events avgmaxtunnel avgendtotal convergefrac ] = ...
        wlProc_doEvAnnealAmplitudeHilbert_MT( events, ...
          samprate, waves.bpfmag, waves.bpffreq, waves.bpfphase, ...
          comparefunc, paramconfig.tunnelmax, paramconfig.totalmax );
    else
      [ events avgmaxtunnel avgendtotal convergefrac ] = ...
        wlProc_doEvAnnealAmplitudeHilbert( events, ...
          samprate, waves.bpfmag, waves.bpffreq, waves.bpfphase, ...
          comparefunc, paramconfig.tunnelmax, paramconfig.totalmax );
    end

    auxdata.AnnAmp_avgmaxtunnel = avgmaxtunnel;
    auxdata.AnnAmp_avgendtotal = avgendtotal;
    auxdata.AnnAmp_convergefrac = convergefrac;

  end


  % Fine-tune all curve-fit parameters if desired.

  if do_annealwave

    if wantmultithread
      [ events avgmaxtunnel avgendtotal convergefrac ] = ...
        wlProc_doEvAnnealAllWave_MT( events, samprate, waves.bpfwave, ...
          comparefunc, paramconfig.tunnelmax, paramconfig.totalmax );
    else
      [ events avgmaxtunnel avgendtotal convergefrac ] = ...
        wlProc_doEvAnnealAllWave( events, samprate, waves.bpfwave, ...
          comparefunc, paramconfig.tunnelmax, paramconfig.totalmax );
    end

    auxdata.AnnWave_avgmaxtunnel = avgmaxtunnel;
    auxdata.AnnWave_avgendtotal = avgendtotal;
    auxdata.AnnWave_convergefrac = convergefrac;

  end

end


%
% Make sure we have a return value.

if ~exist('events', 'var')
  events = [ ];
end


%
% Done.

end


%
% This is the end of the file.
