DIR = ./
DVI = $(DIR)test.dvi
PDF = $(DIR)test.pdf

$(PDF):    $(DVI)
	dvipdfmx -o $(PDF) $<

$(DVI):    日本語.tex
	uplatex -synctex=1 -output-directory=$(DIR) $<

clean:; latexmk -C --outdir=$(DIR) 
