DVI = test.dvi
PDF = test.pdf

$(PDF):    $(DVI)
	dvipdfmx -o $(PDF) $<

clean:; latexmk -C --outdir=./ ../subdir/test.tex
