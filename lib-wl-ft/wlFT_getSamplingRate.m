function ftrate = wlFT_getSamplingRate(trialdata)

% function ftrate = wlFT_getSamplingRate(trialdata)
%
% This function returns the sampling rate used within a Field Trip trial data
% structure. Priority is given to "rawsample", then to "hdr.Fs", and then to
% "1.0 / (time{1}(2) - time{1}(1))". NaN is returned on error.


ftrate = NaN;


if isfield(trialdata, 'fsample')

  ftrate = trialdata.fsample;

elseif isfield(rawdata, 'hdr')

  if isfield(rawdata.hdr, 'Fs')
    ftrate = rawdata.hdr.Fs;
  end

end


if isnan(ftrate)

  timestemp = time{1};

  if 1 < length(timestemp)

    ftrate = timestemp(2) - timestemp(1);
    ftrate = 1.0 / ftrate;

  end

end


%
% Done.

end


%
% This is the end of the file.
