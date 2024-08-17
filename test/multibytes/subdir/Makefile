DIR = ./
DVI = $(DIR)test.dvi
PDF = $(DIR)test.pdf

$(PDF):    $(DVI)
	dvipdfmx -o $(PDF) $<

$(DVI):
	uplatex -synctex=1 -output-directory=$(DIR) `find *.tex`

clean:; latexmk -C --outdir=$(DIR) 
