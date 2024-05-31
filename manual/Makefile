# Womelsdorf Lab burst library - Documentation - Makefile
# Written by Christopher thomas.


GUIDENAME=wlburst-guide
REFNAME=wlburst-reference


GUIDEBITS=\
	$(GUIDENAME)-over.tex		\
	$(GUIDENAME)-math.tex		\
	$(GUIDENAME)-tutorial.tex	\
	$(GUIDENAME).tex

GUIDEAUTO=\
	$(GUIDENAME)-code-config.tex	\
	$(GUIDENAME)-code-real.tex	\
	$(GUIDENAME)-code-synth.tex	\
	$(GUIDENAME)-code-custom.tex	\
	$(GUIDENAME)-formats.tex	\
	$(GUIDENAME)-mincode-ft.tex	\
	$(GUIDENAME)-mincode-synth.tex


REFBITS=\
	$(REFNAME)-over.tex		\
	$(REFNAME).tex

REFAUTO=\
	$(REFNAME)-aux.tex		\
	$(REFNAME)-ft.tex		\
	$(REFNAME)-plot.tex		\
	$(REFNAME)-proc.tex		\
	$(REFNAME)-stats.tex		\
	$(REFNAME)-synth.tex		\
	$(REFNAME)-formats.tex


default: force

guide: $(GUIDENAME).pdf
ref: $(REFNAME).pdf

force: clean guide ref
	make autoclean

clean: tclean autoclean
	rm -f $(GUIDENAME).pdf
	rm -f $(REFNAME).pdf

autoclean:
	rm -f $(GUIDEAUTO)
	rm -f $(REFAUTO)

tclean:
	rm -f $(GUIDENAME)*.log $(GUIDENAME)*.aux $(GUIDENAME)*.toc
	rm -f $(REFNAME)*.log $(REFNAME)*.aux $(REFNAME)*.toc
	rm -f texput.*


$(GUIDENAME).pdf: $(GUIDEBITS)
	./copy-code.pl --outfile=$(GUIDENAME)-mincode-ft.tex --verbatim \
		"--section=Minimal Field Trip Processing Script" \
		"--label=sect-tutor-ftcode" \
		../sample-minimal/do_minimal_ft.m
	./copy-code.pl --outfile=$(GUIDENAME)-mincode-synth.tex --verbatim \
		"--section=Minimal Synthetic Data Processing Script" \
		"--label=sect-tutor-synthcode" \
		../sample-minimal/do_minimal_synth.m
	./copy-code.pl --outfile=$(GUIDENAME)-formats.tex --verbatim \
		"--chapter=Special Structures and Function Handles" \
		"--label=sect-formats" \
		../lib-wl-*/*txt
	./copy-code.pl --outfile=$(GUIDENAME)-code-config.tex --verbatim \
		"--chapter=Sample Code -- Configuration" \
		"--label=sect-code-config" --nosort \
		../sample-ft/do_ft_init.m \
		../sample-ft/do_ft_synth_config.m
	./copy-code.pl --outfile=$(GUIDENAME)-code-real.tex --verbatim \
		"--chapter=Sample Code -- Field Trip Recording" \
		"--label=sect-code-real" --nosort \
		../sample-ft/do_ft_thilo.m
	./copy-code.pl --outfile=$(GUIDENAME)-code-synth.tex --verbatim \
		"--chapter=Sample Code -- Synthetic Data" \
		"--label=sect-code-synth" --nosort \
		../sample-ft/do_ft_synth.m \
		../sample-ft/do_ft_synth_gen.m \
		../sample-ft/do_ft_synth_detect.m \
		../sample-ft/do_ft_synth_post.m \
		../sample-ft/do_ft_synth_calc.m \
		../sample-ft/do_ft_synth_plot.m
	./copy-code.pl --outfile=$(GUIDENAME)-code-custom.tex --verbatim \
		"--chapter=Sample Code -- Defining Custom Functions" \
		"--label=sect-code-custom" --nosort \
		../sample-ft/do_ft_custom.m \
		../sample-ft/do_ft_custom_detect.m
	pdflatex $(GUIDENAME).tex
	pdflatex $(GUIDENAME).tex
	make tclean


$(REFNAME).pdf: $(REFBITS)
	./copy-code.pl --outfile=$(REFNAME)-aux.tex --matlabdoc \
		"--chapter=\`\`wlAux'' Functions" "--label=sect-aux" \
		../lib-wl-aux/*.m
	./copy-code.pl --outfile=$(REFNAME)-ft.tex --matlabdoc \
		"--chapter=\`\`wlFT'' Functions" "--label=sect-ft" \
		../lib-wl-ft/*.m
	./copy-code.pl --outfile=$(REFNAME)-plot.tex --matlabdoc \
		"--chapter=\`\`wlPlot'' Functions" "--label=sect-plot" \
		../lib-wl-plot/*.m
	./copy-code.pl --outfile=$(REFNAME)-proc.tex --matlabdoc \
		"--chapter=\`\`wlProc'' Functions" "--label=sect-proc" \
		../lib-wl-proc/*.m
	./copy-code.pl --outfile=$(REFNAME)-stats.tex --matlabdoc \
		"--chapter=\`\`wlStats'' Functions" "--label=sect-stats" \
		../lib-wl-stats/*.m
	./copy-code.pl --outfile=$(REFNAME)-synth.tex --matlabdoc \
		"--chapter=\`\`wlSynth'' Functions" "--label=sect-synth" \
		../lib-wl-synth/*.m
	./copy-code.pl --outfile=$(REFNAME)-formats.tex --verbatim \
		"--chapter=Special Structures and Function Handles" \
		"--label=sect-formats" ../lib-wl-*/*txt
	pdflatex $(REFNAME).tex
	pdflatex $(REFNAME).tex
	make tclean

gallery:
	cd plots; makegallery.pl --nofolders --width=23% *png; cd ..

pics:

#	make -C pics-gui

pclean:

#	make -C pics-gui clean


# This is the end of the file.
