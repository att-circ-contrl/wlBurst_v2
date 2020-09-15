# wlBurst v2 bug list, feature requests, and abbreviated changelog.

## To-do list and bug list for version 2:

* "default" and "custom" segconfig/paramconfig.

* Plotting and processing functions should check "paramtype" in events rather
  than assuming "chirpramp", especially for reconstructions/scatter-plots.

* Compare functions that tolerate non-"chirpramp" events are needed.

* List merge and duplicate-pruning (clustering) functions are needed. This
  includes splitting out the core of "compare vs ground truth", and offering
  "union of" and "intersection of" variants.

* Provide post-processing/pruning-by-binning functions.

* Annotate function documentation to make it clear which need reconstructed
  event waveforms and which can do without.

* Add enough padding inside wlSynth_traceAddNoise to avoid BPF artifacts.

* Integrate Charlie's wavelet algorithms, or a variant thereof.



## Deferred to version 3:

* Add "filtconfig" for filter tuning parameters, replacing [ min max ] and
hardcoded filter configurations. The workaround now for custom filtering is
to use a wideband "filter" for the call, and pre-filter the waveforms
manually.

* Turn filtconfig, segconfig, and paramconfig into cell arrays, indexed by
band, trial, and channel. This allows per-case tuning of parameters. (It's
a cell array so that structures can have different fields). This replaces
the "override" scheme.

* Burst parameters are stored in a structure within the event record, rather
that at the top level of the event record.

* Add support for "noise" made up of bursts.

* Event detection should include a post-processing/pruning step.

* Add support for specifying a sequence of processing steps (filtering,
segmentation, parameter extraction, post-processing). Multiple steps of
each type can be specified ("type" might not be a meaningful concept).
Steps can produce waveforms (BPF, Hilbert, threshold segment).

* Add support for short epoched data (looping and applying circular filters,
or looping and then unrolling while keeping region-of-interest info).

* Add phase surrogate generation (for looped and linear data).



## Abbreviated changelog:

* 15 Sep 2020 --
Prepared GitHub release.

* 22 Oct 2019 --
Fixed frequency scale bug in spectrogram in wlPlot_plotEventsAgainstWideband.

* 11 Oct 2019 --
Internal release of v2.0 library.


This is the end of the file.
