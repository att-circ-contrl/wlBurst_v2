% Field Trip-related test scripts - Synthetic FT data - Data generation.

%
% Includes.

% FIXME - Assume init has already been called.


%
%
% Configuration.


% Burst type definitions.
% These are band-agnostic.

% Short pulses, not chirped or ramped.
burstpeep.trange = [ 1.0 2.0 ];
burstpeep.framp = [ 1.0 1.0 ];
burstpeep.aramp = [ 1.0 1.0 ];

% Medium length pulses with strong chirping and ramping.
burstchirp.trange = [ 2.0 4.0 ];
burstchirp.framp = [ 0.67 1.5 ];
burstchirp.aramp = [ 0.33 3.0 ];

% Long pulses with weak chirping and ramping. "Fish in a barrel" case.
bursttone.trange = [ 3.0 6.0 ];
bursttone.framp = [ 0.8 1.25 ];
bursttone.aramp = [ 0.75 1.33 ];


% Burst occurrence parameters.

% Synthetic burst traces with realistic content.
% Maybe a bit more frequent than usual.

clear burstdefs;
clear thisdef;

% Allow lots of quiet events.
thisdef.snrrange = [ -20 20 ]; % dB; amplitude 0.1x-10x.

% Theta band: peeps (max duration about 0.5 sec).

thisdef.rate = 0.5;
thisdef.noiseband = bandtheta;
thisdef.fctrrange = bandtheta;
thisdef.durrange = burstpeep.trange;
thisdef.framprange = burstpeep.framp;
thisdef.aramprange = burstpeep.aramp;

burstdefs(1) = thisdef;

% Alpha band: tones and chirps (max duration about 1 sec tones, 0.5 chirps).

thisdef.rate = 0.2;
thisdef.noiseband = bandalpha;
thisdef.fctrrange = bandalpha;
thisdef.durrange = bursttone.trange;
thisdef.framprange = bursttone.framp;
thisdef.aramprange = bursttone.aramp;

burstdefs(2) = thisdef;

thisdef.rate = 0.4;
thisdef.noiseband = bandalpha;
thisdef.fctrrange = bandalpha;
thisdef.durrange = burstchirp.trange;
thisdef.framprange = burstchirp.framp;
thisdef.aramprange = burstchirp.aramp;

burstdefs(3) = thisdef;

% Beta band: chirps (max duration 1/3 sec).

thisdef.rate = 1;
thisdef.noiseband = bandbeta;
thisdef.fctrrange = bandbeta;
thisdef.durrange = burstchirp.trange;
thisdef.framprange = burstchirp.framp;
thisdef.aramprange = burstchirp.aramp;

burstdefs(4) = thisdef;

% Gamma band: chirps (max duration 1/8 sec).

thisdef.rate = 2;
thisdef.noiseband = bandgamma;
thisdef.fctrrange = bandgamma;
thisdef.durrange = burstchirp.trange;
thisdef.framprange = burstchirp.framp;
thisdef.aramprange = burstchirp.aramp;

burstdefs(5) = thisdef;


%
%
% Generate waveform data.


disp('-- Generating synthetic waveforms.');
disp(datetime);

[ traceft groundft ] = wlSynth_genFieldTrip(fsamp, synth_chancount, ...
  synth_trialcount, synth_trialdur, burstdefs, synth_channelratevar, ...
  synth_channelnoisevar);


disp('-- Splitting waveforms by band.');
disp(datetime);


groundftbyband = wlAux_splitEvMatrixByBand(groundft, bandlist);


disp('-- Saving synthetic waveforms to disk.');
disp(datetime);


save( synth_fname_data, 'traceft', 'groundft', 'groundftbyband' );


disp('-- Finished generating waveforms.');


%
% This is the end of the file.
