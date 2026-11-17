# Handling an Unanticipated Intercurrent Event in a Digital Health Intervention Trial

Supplementary Materials, with the Stata code and output used to produce
them. The Supplementary Materials (`supplementary-material.pdf`) describe
a simulation study comparing candidate analysis strategies for a
cluster-randomized trial in which some participants randomized to the
intervention could not receive it, and the application of the chosen
strategy to a fictitious trial dataset.

## Contents

| Path | Description |
| --- | --- |
| `supplementary-material.pdf` | The Supplementary Materials |
| `stata/supplementary_analysis.do` | Generates the fictitious trial data, runs the example analyses and the simulation study, and writes the Stata output in `logs/` |
| `data/disrupted.dta` | The fictitious trial dataset (written by the do-file) |
| `logs/` | Stata output included in the PDF (written by the do-file) |
| `latex/` | LaTeX sources for the PDF |
| `Makefile` | Builds the PDF |

## Reproducing the results

The Stata code requires Stata 18 or later and the `sjlog` command, part
of the Stata Journal's `sjlatex` package (see
<https://www.stata-journal.com/author/>). To install `sjlog`, in Stata:

```stata
net from http://www.stata-journal.com/production
net install sjlatex
```

Then, from this directory:

```stata
do stata/supplementary_analysis.do
```

The do-file sets the random-number seed, so its results are reproducible.
The files in `data/` and `logs/` were produced with Stata 18. Running the
do-file with StataNow 19.5 reproduces them, except that the output of
`reshape` in `logs/code_example_14.log.tex` differs in white space.

## Building the PDF

Requires a TeX distribution that provides `pdflatex`, `bibtex` and
`latexmk` (such as TeX Live). From this directory:

```sh
make
```
