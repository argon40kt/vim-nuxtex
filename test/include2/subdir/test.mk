DIR = ./subdir/
DVI = $(DIR)test.dvi
PDF = $(DIR)test.pdf

$(PDF):    $(DVI)
	dvipdfmx -o $(PDF) $<

$(DVI):    $(DIR)test.tex
	uplatex -synctex=1 -output-directory=$(DIR) $<

clean:; latexmk -C --outdir=$(DIR) 