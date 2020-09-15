function [ bestvec longestprobe endtotal ] = ...
  wlProc_doAnneal(scalevec, errfunc, maxprobes, maxtotal)

% function [ bestvec longestprobe endtotal ] = ...
%   wlProc_doAnneal(scalevec, errfunc, maxprobes, maxtotal)
%
% This function performs simulated annealing, searching for a perturbation
% vector about a known solution that results in the minimum "error" value.
%
% Search steps are drawn from a scaled Gaussian distribution. Radius is
% scaled by an exponential factor, and components are further scaled by
% the amounts dictated by "scalevec". The purpose of exponential scaling is
% to allow tunnelling between distant minima while also allowing fine-scale
% gradient descent, without foreknowledge of the scales involved. The purpose
% of "scalevec" is to ensure that for a given choice of exponential scale,
% feature sizes in all directions are roughly comparable. If feature sizes
% are not known, all elements can be set to unity and annealing will still
% work (just with slower convergence).
% FIXME - We might want an inverted whitening matrix instead of "scalevec".
%
% Details of the problem being optimized are encapsulated in "errfunc". The
% annealing function provides "errfunc" with a perturbation vector (with the
% starting state being the zero vector). Interpretation of that vector in
% solution space is up to "errfunc".
%
% "scalevec" is a [1xN] vector whose components indicate the "natural scale"
%   of their respective state vector/perturbation vector elements.
% "errfunc" is a function for evaluating proposed perturbed solutions. This
%   has the form: [ isvalid error ] = errfunc(perturbvec)
% "maxprobes" is the maximum number of unproductive perturbation attempts that
%   can be made in one step before annealing terminates.
% "maxtotal" is the maximum number of total perturbation attempts, productive
%   or not, that can be made before annealing terminates.
%
% "bestvec" is the perturbation vector obtained after annealing.
% "longestprobe" is the maximum number of perturbation attempts actually made
%   during any single probe. If this is less than "maxprobes", annealing
%   didn't converge before reaching "maxtotal" attempts.
% "endtotal" is the total number of perturbation attempts actually made. If
%   this is less than "maxtotal", annealing did converge.


%
% Initialize.

bestvec = zeros(size(scalevec));
[ isvalid, besterr ] = errfunc(bestvec);

if ~isvalid
  besterr = inf;
end

longestprobe = 0;


%
% Continue trying to perturb the solution until perturbations are no longer
% useful, or we hit the global cap.

pcount = 0;
pbad = 0;

% FIXME - Diagnostics.
if false
disp(sprintf('.  Error: %.6f', besterr));
disp(bestvec);
end

while (pbad <= maxprobes) && (pcount <= maxtotal)

  % Generate a probe vector.

  % The components of a spherical Gaussian are Gaussians, so what we get here
  % has a spherical distribution (before we deform it).
  probe = normrnd(0, 1, size(scalevec));
  probe = probe .* scalevec;

  % Scale by e^2 .. e^-14. This is about 10x .. 1/1Mx.
  probe = probe * exp( rand()*16 - 14 );


  % See if this a) is valid and b) helped.

  [ isvalid thiserr ] = errfunc(bestvec + probe);

  if isvalid && (thiserr < besterr)

    besterr = thiserr;
    bestvec = bestvec + probe;
    pbad = 0;

  else

    pbad = pbad + 1;

    if pbad > longestprobe
      longestprobe = pbad;
    end

  end


  % No matter what, increment our attempt count.
  pcount = pcount + 1;

end


% Record the total number of attempts.
endtotal = pcount;


%
% Done.

end


%
% This is the end of the file.
