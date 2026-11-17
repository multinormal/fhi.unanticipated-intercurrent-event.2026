# Builds supplementary-material.pdf from the LaTeX sources in latex/ and the
# Stata output in logs/.
#
# Uses latexmk, which reruns pdflatex/bibtex as many times as needed.

MAIN = supplementary-material
LATEXMK = latexmk
LATEXMKFLAGS = -pdf -bibtex -interaction=nonstopmode -halt-on-error -cd

SOURCES = latex/$(MAIN).tex latex/content.tex latex/bibliography.bib \
          latex/firstauthor.bst $(wildcard logs/*.log.tex)

.PHONY: all clean

all: $(MAIN).pdf

$(MAIN).pdf: $(SOURCES)
	$(LATEXMK) $(LATEXMKFLAGS) latex/$(MAIN).tex
	cp latex/$(MAIN).pdf $@

clean:
	$(LATEXMK) -C -cd latex/$(MAIN).tex
