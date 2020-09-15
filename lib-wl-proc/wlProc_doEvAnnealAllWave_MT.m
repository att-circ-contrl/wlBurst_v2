function [ newevents avglongestprobe avgendtotal convergefrac ] = ...
  wlProc_doEvAnnealAllWave_MT( ...
    oldevents, samprate, wavedata, ...
    comparefunc, maxprobes, maxtotal)

% function [ newevents avglongestprobe avgendtotal convergefrac ] = ...
%   wlProc_doEvAnnealAllWave_MT( ...
%     oldevents, samprate, wavedata, ...
%     comparefunc, maxprobes, maxtotal)
%
% This function anneals an event list with approximate parameters, producing
% a list with parameters perturbed to better match the input.
% The "All" implementation anneals all event parameters, rather than fitting.
% The "Wave" implementation fits to the signal waveform, rather than to
% the analytic version.
% This is a multithreaded wrapper for the single-threaded version.
%
% "oldevents" is the input event list, with format per EVENTFORMAT.txt.
% "samprate" is the number of samples per second in the signal data.
% "wavedata" is the signal waveform the event was extracted from.
% "comparefunc" is a function handle for an event comparison function, as
%   described in COMPAREFUNC.txt. Perturbed events must "match" the original
%   event to be valid. This has the form:
%     [ ismatch distance ] = comparefunc(evfirst, evsecond)
% "maxprobes" is the maximum number of unproductive perturbation attempts that
%   can be made in one step before annealing terminates.
% "maxtotal" is the maximum number of total perturbation attempts, productive
%   or not, that can be made before annealing terminates.
%
% "newevents" is the perturbed event list. Annealing statistics are stored in
%   "auxdata" (as "AnnWave_maxtunnel", "AnnWave_total", "AnnWave_errstart",
%   and "AnnWave_errfinal").
% "avglongestprobe" is the average across events of the maximum number of
%   perturbation attempts made during any single probe during annealing.
% "avgendtotal" is the average across events of the total number of
%   perturbation attempts made while annealing an event.
% "convergefrac" is the fraction of events where annealing took fewer than
%   95% of "maxtotal" perturbation attempts.


% Parallelize this by calling the single-threaded version with lists of
% size 1. This has overhead but there should still be a net benefit.


% Set up averages so that we can parallelize annealing.

longestprobes = zeros(size(oldevents));
endtotals = zeros(size(oldevents));

avglongestprobe = 0;
avgendtotal = 0;


% Anneal each event.

parfor evidx = 1:length(oldevents)

  thisev = oldevents(evidx);

  % Wrap the single-threaded version.

  [ templist thislongestprobe thisendtotal thisconvergefrac ] = ...
    wlProc_doEvAnnealAllWave( [ thisev ], samprate, wavedata, ...
      comparefunc, maxprobes, maxtotal);


  % Store the new event.

  newevents(evidx) = templist(1);


  % Update statistics.

  longestprobes(evidx) = thislongestprobe;
  endtotals(evidx) = thisendtotal;

  % Ignore convergefrac; we calculate this later from aggregate data.

end


%
% Check for the empty-list case, so that we have a return value.

if 1 > length(oldevents)
  newevents = [];
  convergefrac = 0;
end


%
% Compute annealing statistics.

if 0 < length(oldevents)
  avglongestprobe = mean(longestprobes);
  avgendtotal = mean(endtotals);
  convergefrac = sum(endtotals < (0.95 * maxtotal)) / length(endtotals);
end


%
% Done.

end


%
%
%
% Helper functions.


%
% Helper function: Turning a parameter vector into an event record.
% This _adds_ the vector to the relevant parameters.
% The result is not guaranteed to be valid!
% Components: Start (secs), duration, a1, a2, rollon, rolloff, f1, f2, p1.

function newev = helper_makeEvFromVec(paramvec, oldev)

  newev = oldev;
  newev.sampstart = newev.sampstart + round(paramvec(1) * newev.samprate);
  newev.duration = newev.duration + paramvec(2);
  newev.a1 = newev.a1 + paramvec(3);
  newev.a2 = newev.a2 + paramvec(4);
  newev.rollon = newev.rollon + paramvec(5);
  newev.rolloff = newev.rolloff + paramvec(6);
  newev.f1 = newev.f1 + paramvec(7);
  newev.f2 = newev.f2 + paramvec(8);
  newev.p1 = newev.p1 + paramvec(9);

  % Wrap phase to -pi..pi.
  newev.p1 = mod(newev.p1 + pi, 2*pi) - pi;

  % Curve types are set by testing both versions.

end  % helper_makeEvFromVec


%
% Helper function: Setting event amplitude and frequency types correctly.
% The event parameters must be valid!

function [ newev error ] = helper_makeCorrectSlopes(oldev, wavedata)

  % Initialize.

  newev = oldev;
  newev.atype = 'linear';
  newev.ftype = 'linear';
  error = inf;


  % Iterate cases.

  for aidx = { 'linear' 'logarithmic' }
    for fidx = { 'linear' 'logarithmic' }

      testev = oldev;
      testev.atype = aidx{1};
      testev.ftype = fidx{1};

      reconlist = wlAux_getReconFromParams( [ testev ] );
      testev = reconlist(1);

      testerr = wlProc_calcWaveErrorRelative(wavedata, testev.sampstart, ...
        testev.wave, testev.s1);

      if testerr < error
        % This case looks better. Record it.
        newev.atype = aidx{1};
        newev.ftype = fidx{1};
        error = testerr;
      end

    end
  end

end


%
% Helper function: Validity and error calculation by waveform comparison.

function [ isvalid error ] = helper_calcValidError(paramvec, oldev, ...
  wavedata, comparefunc)

  % Reconstruct the event parameters from the state vector.

  newev = helper_makeEvFromVec(paramvec, oldev);


  % Check validity, first.

  isvalid = false;
  error = inf;

  sampdur = round(newev.duration * newev.samprate);
  samponh = round(0.5 * newev.rollon * newev.samprate);
  sampoffh = round(0.5 * newev.rolloff * newev.samprate);

  % Force nonzero roll-off.
  rollmin = 0.1 * newev.duration;

  % Using > rather than >= just in case there are rounding errors.

  if ( (1 + samponh) < newev.sampstart ) ...
    && ( length(wavedata) > (newev.sampstart + sampdur + sampoffh) ) ...
    && ( newev.duration > (0.5 * (newev.rollon + newev.rolloff)) ) ...
    && ( newev.a1 > 0 ) && ( newev.a2 > 0 ) ...
    && ( newev.rollon >= rollmin ) && ( newev.rolloff >= rollmin ) ...
    && ( newev.f1 > 0 ) && ( newev.f2 > 0 )

    % Check against the old event.
    if comparefunc(oldev, newev)

      % The event is valid. Calculate magnitude error.
      % Our slope type helper function does this.

      isvalid = true;
      [ newev error ] = helper_makeCorrectSlopes(newev, wavedata);

    end
  end

end  % helper_calcValidError


%
% This is the end of the file.
