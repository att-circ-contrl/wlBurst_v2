# wlBurst v2 Library

## Overview

The wlBurst library provides Matlab scripts for identifying and
characterizing transient oscillations in neural signals ("LFP bursts").
This repository contains version 2 of the library, which is the active
branch as of September 2020.

The wlBurst project is copyright (c) 2018-2020 by Vanderbilt University, and
is released under the Creative Commons Attribution 4.0 International
License.


## Repository Organization

The following top-level files are relevant:

* README.md -- This file.
* LICENSE.md -- Licensing information (per above).
* TODO.md -- Abbreviated changelog and bug list/feature list.

The following directories contain library code:

* lib-wl-aux -- Auxiliary functions that don't fall into the other categories.
* lib-wl-ft -- Wrappers that perform library operations on Field Trip data
structures and interconvert with Field Trip's data format.
* lib-wl-plot -- Helper functions for plotting. These are mostly
quick-and-dirty routines for testing, rather than for publishable graphs.
* lib-wl-proc -- Functions that perform segmentation and feature extraction
on oscillatory burst events in LFP signals.
* lib-wl-synth -- Functions for generating synthetic LFP waveforms with
known ground truth for testing.

For further information on the library functions and their use, see the
User Guide and the Function Reference (included in this repository).

The following directories contain other resources:

* manual -- LaTeX build directory for project documentation. Use `make -C manual` to build it.
* sample-minimal -- Minimal working examples of programs that use the libraries.


This is the end of the file.
