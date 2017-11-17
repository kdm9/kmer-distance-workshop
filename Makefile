RESOURCEDIR   := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))/.resources
CSS           := $(RESOURCEDIR)/kultiad-serif.css
REVEAL 		  := $(RESOURCEDIR)/reveal.js/
KATEXDIR 	  := $(RESOURCEDIR)/katex
KATEX		  := --katex=$(KATEXDIR)/katex.min.js --katex-stylesheet=$(KATEXDIR)/katex.min.css

PANDOC_FLAGS  := -S --filter pandoc-citeproc
HTML_FLAGS    := $(PANDOC_FLAGS) -t html5 -c $(CSS) --self-contained $(KATEX)
PDF_FLAGS     := $(PANDOC_FLAGS)                        \
					--template=$(RESOURCEDIR)/kdm.latex \
					-V geometry:margin=1in              \
					-V caption:margin=1cm              \
					-V papersize=A4                     \
					-V fontsize=12pt                    \
					-V documentclass=article
SLIDE_FLAGS   := $(PANDOC_FLAGS) -V revealjs-url=$(REVEAL) -t revealjs --self-contained $(KATEX)

MDs := $(wildcard *.md)
PDFs := $(patsubst %.md,%.pdf,$(MDs))
HTMLs := $(patsubst %.md,%.html,$(MDs))
MDPRES := $(wildcard *.mdpres)
SLIDES := $(patsubst %.mdpres,%.html,$(MDPRES))

.PHONY: all pdf html slides clean

all: html slides

pdf: $(PDFs)

html: $(HTMLs)

slides: $(SLIDES)

clean:
	rm -f $(PDFs) $(HTMLs) $(SLIDES)

%.pdf: %.md
	pandoc $(PDF_FLAGS) -o $(@F) $(<F)
%.html: %.md
	pandoc $(HTML_FLAGS) -o $(@F) $(<F)
%.html: %.mdpres
	pandoc $(SLIDE_FLAGS) -o $(@F) $(<F)

